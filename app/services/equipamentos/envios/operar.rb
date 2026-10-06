module Equipamentos
  module Envios
    # O que acontece com um envio depois de criado. Cada ação confere quem pode, muda o envio e os equipamentos,
    # registra no histórico de cada equipamento, audita e avisa.
    #
    #   cancelar_item      quem criou (ou o administrador) desiste de um equipamento ainda não recebido
    #   receber_item       quem recebe dá o recebido de um equipamento da MOVIMENTAÇÃO: ele passa a ser da nova unidade
    #   aceitar            quem recebe aceita o termo do EMPRÉSTIMO/CAUTELA: os equipamentos ficam com a unidade dele
    #   devolver           quem está com o equipamento emprestado inicia a devolução, indicando quem recebe na origem
    #   receber_devolucao  a pessoa indicada confirma que recebeu de volta, com observação
    #
    # O administrador pode fazer a parte de quem recebe em nome da pessoa; fica registrado quem fez.
    class Operar
      def self.call(...) = new(...).call

      def initialize(envio:, acao:, ator:, item_id: nil, item_ids: nil, para_id: nil, observacao: nil)
        @envio = envio
        @acao = acao.to_s
        @ator = ator
        @ids = (Array(item_ids) + [ item_id ]).compact.map(&:to_i).uniq
        @para = ::User.ativos.find_by(id: para_id)
        @observacao = observacao.to_s.squish.presence
      end

      def call
        return falha("Ação inválida.") unless %w[cancelar_item receber_item aceitar devolver receber_devolucao].include?(@acao)
        return falha("Este envio já foi encerrado.") unless @envio.em_andamento?

        erro = Equipamentos::Movimentacao.transaction { send(@acao) }
        return falha(erro) if erro.is_a?(String)

        Avisos.atualizar_telas(@envio)
        Core::Resultado.sucesso(@envio)
      end

      private

      def admin? = Acesso.pode?(@ator, Acesso::ADMINISTRAR)
      def criador? = @envio.criada_por_id == @ator.id
      def responsavel? = @envio.responsavel_id == @ator.id
      # "em nome de Fulano", quando é o administrador fazendo a parte de outra pessoa.
      def em_nome_de(user) = @ator.id == user&.id ? "" : " (feito por #{@ator.nome}, administrador, em nome de #{user&.nome || 'outra pessoa'})"
      def linhas(status) = @envio.itens.select { |linha| linha.status == status && (@ids.empty? || @ids.include?(linha.item_id)) }

      def cancelar_item
        return "Só quem criou o envio pode cancelar." unless criador? || admin?

        alvo = linhas("pendente")
        return "Este equipamento já foi recebido ou cancelado." if alvo.empty?

        alvo.each do |linha|
          linha.update!(status: "cancelado", cancelado_em: Time.current, cancelado_por: @ator)
          linha.item.update!(situacao: "disponivel")
          linha.item.registrar_evento((@envio.emprestimo? ? "emprestimo_cancelado" : "movimentacao_cancelada"), @ator,
                                      "#{@envio.nome_do_tipo} #{@envio.codigo} para #{@envio.destino_nome}: envio cancelado.#{em_nome_de(@envio.criada_por)}")
        end
        auditar("item_cancelado", alvo)
        encerrar_se_acabou
        Avisos.notificar(@envio.responsavel, @envio, @ator, "cancelado", "Envio de equipamento cancelado", "#{@envio.codigo}: #{alvo.size} equipamento(s) não serão mais enviados.")
        nil
      end

      def receber_item
        return "Empréstimo e cautela são recebidos pelo aceite do termo." if @envio.emprestimo?
        return "Só #{@envio.responsavel_nome} pode dar o recebido." unless responsavel? || admin?

        alvo = linhas("pendente")
        return "Este equipamento já foi recebido ou cancelado." if alvo.empty?

        alvo.each do |linha|
          linha.update!(status: "recebido", recebido_em: Time.current, recebido_por: @ator)
          linha.item.update!(rh_unidade_id: @envio.destino_rh_unidade_id, unidade_nome: @envio.destino_nome, situacao: "disponivel")
          linha.item.registrar_evento("movimentacao_recebida", @ator,
                                      "Movimentação #{@envio.codigo}: de #{@envio.origem_nome} para #{@envio.destino_nome}, recebido por #{@envio.responsavel_nome}.#{em_nome_de(@envio.responsavel)}")
        end
        auditar("item_recebido", alvo)
        encerrar_se_acabou
        Avisos.notificar(@envio.criada_por, @envio, @ator, "recebido", "Equipamento recebido", "#{@envio.codigo}: #{@envio.responsavel_nome} recebeu #{alvo.size} equipamento(s) em #{@envio.destino_nome}.")
        nil
      end

      def aceitar
        return "Só empréstimo e cautela têm termo." unless @envio.emprestimo?
        return "Só #{@envio.responsavel_nome} pode aceitar o termo." unless responsavel? || admin?
        return "O termo deste envio já foi aceito." if @envio.aceita?

        alvo = @envio.itens.select(&:pendente?)
        return "Não há equipamento aguardando aceite neste envio." if alvo.empty?

        @envio.update!(aceita_em: Time.current, termo: Termo.texto(@envio))
        alvo.each do |linha|
          linha.update!(status: "emprestado", recebido_em: Time.current, recebido_por: @ator)
          linha.item.update!(situacao: "emprestado", posse_rh_unidade_id: @envio.destino_rh_unidade_id, posse_unidade_nome: @envio.destino_nome)
          linha.item.registrar_evento("emprestimo_aceito", @ator,
                                      "#{@envio.nome_do_tipo} #{@envio.codigo}: termo aceito por #{@envio.responsavel_nome} (#{@envio.destino_nome}). " \
                                      "Devolução prevista para #{I18n.l(@envio.previsao_devolucao)}.#{em_nome_de(@envio.responsavel)}")
        end
        auditar("termo_aceito", alvo)
        Avisos.notificar(@envio.criada_por, @envio, @ator, "aceito", "Termo de #{@envio.nome_do_tipo.downcase} aceito", "#{@envio.codigo}: #{@envio.responsavel_nome} aceitou o termo e está com #{alvo.size} equipamento(s).")
        nil
      end

      # Também troca a pessoa indicada, quando a devolução já foi iniciada e ninguém recebeu.
      def devolver
        return "Só empréstimo e cautela têm devolução." unless @envio.emprestimo?
        return "Só #{@envio.responsavel_nome} pode devolver." unless responsavel? || admin?
        return "Escolha quem vai receber a devolução." unless @para
        return "#{@para.nome} não está lotado(a) em #{@envio.origem_nome}." unless Rh::Api.ids_dos_usuarios_da_unidade(@envio.origem_rh_unidade_id).include?(@para.id)

        alvo = linhas("emprestado") + linhas("devolucao_pendente")
        return "Não há equipamento com você neste envio para devolver." if alvo.empty?

        alvo.each do |linha|
          troca = linha.devolucao_pendente?
          linha.update!(status: "devolucao_pendente", devolucao_pedida_em: linha.devolucao_pedida_em || Time.current, devolver_para: @para, devolver_para_nome: @para.nome)
          linha.item.registrar_evento("devolucao_pedida", @ator,
                                      "#{@envio.nome_do_tipo} #{@envio.codigo}: devolução #{troca ? 'redirecionada' : 'iniciada'} para #{@para.nome} (#{@envio.origem_nome}).#{em_nome_de(@envio.responsavel)}")
        end
        auditar("devolucao_pedida", alvo, para: @para.nome)
        Avisos.notificar(@para, @envio, @ator, "devolucao", "Devolução de equipamento para você receber", "#{@envio.codigo}: #{@envio.responsavel_nome} está devolvendo #{alvo.size} equipamento(s).")
        nil
      end

      def receber_devolucao
        alvo = linhas("devolucao_pendente").select { |linha| linha.devolver_para_id == @ator.id || admin? }
        return "Não há devolução deste envio para você receber." if alvo.empty?

        alvo.each do |linha|
          indicado = linha.devolver_para
          linha.update!(status: "devolvido", devolvido_em: Time.current, devolucao_recebida_por: @ator, observacao_da_devolucao: @observacao)
          linha.item.update!(situacao: "disponivel", posse_rh_unidade_id: nil, posse_unidade_nome: nil)
          linha.item.registrar_evento("devolucao_recebida", @ator,
                                      "#{@envio.nome_do_tipo} #{@envio.codigo}: devolvido por #{@envio.responsavel_nome} e recebido em #{@envio.origem_nome}." \
                                      "#{" Observação: #{@observacao}" if @observacao}#{em_nome_de(indicado)}")
        end
        auditar("devolucao_recebida", alvo, observacao: @observacao)
        encerrar_se_acabou
        Avisos.notificar([ @envio.responsavel, @envio.criada_por ], @envio, @ator, "devolvido", "Devolução recebida", "#{@envio.codigo}: #{alvo.size} equipamento(s) recebidos de volta em #{@envio.origem_nome}.")
        nil
      end

      # Sem nada pendente, emprestado ou em devolução, o envio termina: concluído se algo chegou, cancelado se nada.
      def encerrar_se_acabou
        linhas = @envio.itens.reload
        return if linhas.any?(&:aberto?)

        @envio.update!(status: (linhas.all?(&:cancelado?) ? "cancelada" : "concluida"), encerrada_em: Time.current)
      end

      def auditar(evento, linhas, **dados)
        Core::Api.auditar(evento: "equipamentos.envio.#{evento}", alvo: @envio, ator: @ator,
                          dados: { codigo: @envio.codigo, equipamentos: linhas.map { |linha| linha.item.identificacao },
                                   pelo_administrador: (true if admin? && !criador? && !responsavel? && linhas.none? { |linha| linha.devolver_para_id == @ator.id }) }.merge(dados).compact)
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @envio)
    end
  end
end
