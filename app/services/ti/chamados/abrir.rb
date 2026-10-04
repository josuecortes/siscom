module Ti
  module Chamados
    # Abre um chamado: confere se o usuário pode abrir a solicitação (perfis de abertura), a
    # lotação escolhida, o limite de chamados abertos e as respostas do formulário. Registra o
    # evento, audita e avisa quem pode pegar o chamado (membros dos grupos técnicos da solicitação).
    #
    # Em falha, `objeto` é um Formulario com os erros para a tela mostrar de volta.
    class Abrir
      PERMISSAO = "ti.chamados.abrir".freeze

      Formulario = Struct.new(:solicitacao, :lotacoes, :lotacao_id, :respostas, :erros, keyword_init: true)

      def self.call(...) = new(...).call

      def initialize(user:, problema_id:, lotacao_id: nil, respostas: {})
        @user = user
        @problema_id = problema_id
        @lotacao_id = lotacao_id.presence&.to_i
        @entradas = respostas
      end

      def call
        return falha(base: "Você não pode abrir chamados.") unless Core::Autorizacao.new(@user).pode?(PERMISSAO)

        @solicitacao = Ti::Problema.que_pode_abrir(@user).find_by(id: @problema_id)
        return falha(solicitacao: "deve ser escolhida na lista") unless @solicitacao

        @lotacoes = Rh::Api.lotacoes_ativas(@user)
        lotacao = @lotacoes.size <= 1 ? @lotacoes.first : @lotacoes.find { |item| item.id == @lotacao_id }
        @respostas = Respostas.new(@solicitacao, @entradas)
        erros = @respostas.erros.dup
        erros[:lotacao] = "deve ser escolhida" if @lotacoes.size > 1 && lotacao.nil?
        erros[:base] = "Você já tem um chamado em andamento para esta solicitação. Acompanhe-o em Meus chamados." if repetido?
        return falha(erros) if erros.any?

        chamado = gravar(lotacao)
        avisar(chamado)
        Core::Resultado.sucesso(chamado)
      end

      private

      def repetido?
        !@solicitacao.permite_varios_abertos? && Ti::Chamado.em_andamento.exists?(solicitante: @user, problema: @solicitacao)
      end

      def gravar(lotacao)
        Ti::Chamado.transaction do
          chamado = Ti::Chamado.create!(
            problema: @solicitacao, prioridade: @solicitacao.prioridade_padrao, solicitante: @user, solicitante_nome: @user.nome,
            solicitante_email: @user.email, rh_unidade_id: lotacao&.unidade&.id, unidade_nome: lotacao&.unidade&.then { |unidade| nome_da(unidade) },
            funcao_nome: lotacao&.funcao, aberto_em: Time.current
          )
          @respostas.valores.each do |valor|
            registro = chamado.valores.create!(campo_problema: valor[:campo], rotulo: valor[:campo].rotulo, tipo: valor[:campo].tipo,
                                               valor_texto: valor[:texto], valor_json: valor[:json] || {})
            registro.arquivos.attach(valor[:arquivos]) if valor[:arquivos].present?
          end
          chamado.eventos.create!(tipo: "aberto", para_status: chamado.status, ator: @user, ator_nome: @user.nome, ocorrido_em: chamado.aberto_em,
                                  nota: "Chamado aberto pelo solicitante.")
          Core::Api.auditar(evento: "ti.chamado.aberto", alvo: chamado, ator: @user, dados: { codigo: chamado.codigo, solicitacao: @solicitacao.nome })
          chamado
        end
      end

      def nome_da(unidade) = [ unidade.sigla, unidade.nome ].compact_blank.join(" - ")

      # Regra do seed: chamado novo avisa todos que podem pegá-lo.
      def avisar(chamado)
        operadores = ::User.ativos.where(id: Ti::MembroGrupo.where(grupo_tecnico_id: @solicitacao.grupos_tecnicos.ativo.select(:id)).select(:user_id))
                           .where.not(id: @user.id)
        Core::Api.notificar(destinatarios: operadores, evento: "ti.chamado.aberto", titulo: "Novo chamado na fila",
                            mensagem: "#{chamado.codigo} - #{@solicitacao.nome}", alvo: chamado, ator: @user)
      end

      def falha(erros)
        formulario = Formulario.new(solicitacao: @solicitacao, lotacoes: @lotacoes || [], lotacao_id: @lotacao_id, respostas: @respostas, erros: erros)
        Core::Resultado.falha(erros.values, objeto: formulario)
      end
    end
  end
end
