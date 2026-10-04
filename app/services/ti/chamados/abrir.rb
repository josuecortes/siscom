module Ti
  module Chamados
    # Abre um chamado: confere se o usuário pode abrir a solicitação (perfis de abertura), a
    # lotação escolhida, o limite de chamados abertos e as respostas do formulário. Registra o
    # evento, audita e avisa quem pode pegar o chamado (membros dos grupos técnicos da solicitação).
    #
    # Com `aberto_por` (alguém da TI com `ti.chamados.abrir_para_outro`), o chamado é aberto em nome
    # de `user`: valem os perfis de abertura e as lotações dele, e ele é o dono; fica registrado quem abriu.
    #
    # Em falha, `objeto` é um Formulario com os erros para a tela mostrar de volta.
    class Abrir
      PERMISSAO = "ti.chamados.abrir".freeze
      PERMISSAO_PARA_OUTRO = "ti.chamados.abrir_para_outro".freeze

      Formulario = Struct.new(:solicitante, :solicitacao, :lotacoes, :lotacao_id, :respostas, :erros, keyword_init: true)

      def self.call(...) = new(...).call

      def initialize(user:, problema_id:, lotacao_id: nil, respostas: {}, aberto_por: nil)
        @user = user
        @aberto_por = aberto_por unless aberto_por == user
        @problema_id = problema_id
        @lotacao_id = lotacao_id.presence&.to_i
        @entradas = respostas
      end

      def call
        return falha(solicitante: "deve ser escolhido na lista") unless @user&.ativo?
        return falha(base: "Você não pode abrir chamados.") unless autorizado?

        @solicitacao = Ti::Problema.que_pode_abrir(@user).find_by(id: @problema_id)
        return falha(solicitacao: "deve ser escolhida na lista") unless @solicitacao

        @lotacoes = Rh::Api.lotacoes_ativas(@user)
        lotacao = @lotacoes.size <= 1 ? @lotacoes.first : @lotacoes.find { |item| item.id == @lotacao_id }
        @respostas = Respostas.new(@solicitacao, @entradas)
        erros = @respostas.erros.dup
        erros[:lotacao] = "deve ser escolhida" if @lotacoes.size > 1 && lotacao.nil?
        erros[:base] = mensagem_de_repetido if repetido?
        return falha(erros) if erros.any?

        chamado = gravar(lotacao)
        avisar(chamado)
        Core::Resultado.sucesso(chamado)
      end

      private

      def autorizado?
        return Core::Autorizacao.new(@aberto_por).pode?(PERMISSAO_PARA_OUTRO) if @aberto_por

        Core::Autorizacao.new(@user).pode?(PERMISSAO)
      end

      def repetido?
        !@solicitacao.permite_varios_abertos? && Ti::Chamado.em_andamento.exists?(solicitante: @user, problema: @solicitacao)
      end

      def mensagem_de_repetido
        return "#{@user.nome} já tem um chamado em andamento para esta solicitação." if @aberto_por

        "Você já tem um chamado em andamento para esta solicitação. Acompanhe-o em Meus chamados."
      end

      def gravar(lotacao)
        Ti::Chamado.transaction do
          chamado = Ti::Chamado.create!(
            problema: @solicitacao, prioridade: @solicitacao.prioridade_padrao, solicitante: @user, solicitante_nome: @user.nome,
            solicitante_email: @user.email, rh_unidade_id: lotacao&.unidade&.id, unidade_nome: lotacao&.unidade&.then { |unidade| nome_da(unidade) },
            funcao_nome: lotacao&.funcao, aberto_em: Time.current, aberto_por: @aberto_por
          )
          @respostas.valores.each do |valor|
            registro = chamado.valores.create!(campo_problema: valor[:campo], rotulo: valor[:campo].rotulo, tipo: valor[:campo].tipo,
                                               valor_texto: valor[:texto], valor_json: valor[:json] || {})
            registro.arquivos.attach(valor[:arquivos]) if valor[:arquivos].present?
          end
          ator = @aberto_por || @user
          chamado.eventos.create!(tipo: "aberto", para_status: chamado.status, ator: ator, ator_nome: ator.nome, ocorrido_em: chamado.aberto_em,
                                  nota: (@aberto_por ? "Chamado aberto por #{ator.nome} em nome de #{@user.nome}." : "Chamado aberto pelo solicitante."))
          Core::Api.auditar(evento: "ti.chamado.aberto", alvo: chamado, ator: ator,
                            dados: { codigo: chamado.codigo, solicitacao: @solicitacao.nome, em_nome_de: (@user.id if @aberto_por) }.compact)
          chamado
        end
      end

      def nome_da(unidade) = [ unidade.sigla, unidade.nome ].compact_blank.join(" - ")

      # Regra do seed: chamado novo avisa todos que podem pegá-lo.
      def avisar(chamado)
        operadores = ::User.ativos.where(id: Ti::MembroGrupo.where(grupo_tecnico_id: @solicitacao.grupos_tecnicos.ativo.select(:id)).select(:user_id))
                           .where.not(id: [ @user.id, @aberto_por&.id ].compact)
        Core::Api.notificar(destinatarios: operadores, evento: "ti.chamado.aberto", titulo: "Novo chamado aberto",
                            mensagem: "#{chamado.codigo} - #{@solicitacao.nome}", alvo: chamado, ator: @aberto_por || @user,
                            url_acao: Rails.application.routes.url_helpers.ti_operacao_path(chamado))
        Avisos.atualizar_telas(chamado)
        return unless @aberto_por

        Core::Api.notificar(destinatarios: [ @user ], evento: "ti.chamado.aberto_em_seu_nome", titulo: "Chamado aberto em seu nome",
                            mensagem: "#{@aberto_por.nome} abriu o chamado #{chamado.codigo} (#{@solicitacao.nome}) para você.",
                            alvo: chamado, ator: @aberto_por)
      end

      def falha(erros)
        formulario = Formulario.new(solicitante: @user, solicitacao: @solicitacao, lotacoes: @lotacoes || [], lotacao_id: @lotacao_id, respostas: @respostas, erros: erros)
        Core::Resultado.falha(erros.values, objeto: formulario)
      end
    end
  end
end
