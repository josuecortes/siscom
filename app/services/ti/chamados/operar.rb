module Ti
  module Chamados
    # As ações da operação sobre um chamado (porta da ação `triage` do tickets_controller do seed).
    # Cada ação confere quem pode, de quais etapas pode sair, muda o chamado, registra o evento,
    # audita, avisa (regras do seed) e atualiza as telas abertas.
    #
    #   Ti::Chamados::Operar.call(chamado:, acao: "assumir", ator: user)
    #   Ti::Chamados::Operar.call(chamado:, acao: "concluir", ator: user, nota: "Trocado o cabo de rede.")
    class Operar
      Acao = Data.define(:chave, :rotulo, :titulo, :pede_nota, :rotulo_nota, :de, :evento, :icone)

      ACOES = [
        Acao.new("assumir", "Assumir chamado", "Assumir chamado", false, nil, %w[aberto aguardando_tecnico em_triagem em_atendimento impedido], "assumido", :user_follow),
        Acao.new("encaminhar", "Encaminhar para técnico", "Encaminhar para atendimento técnico", true, "Resultado da triagem", %w[aberto em_triagem], "encaminhado", :send),
        Acao.new("devolver", "Pedir ajuste ao solicitante", "Pedir ajuste ao solicitante", true, "Orientação para o solicitante",
                 %w[em_triagem em_atendimento impedido], "devolvido", :pencil),
        Acao.new("impedir", "Marcar impedimento", "Marcar impedimento", true, "Motivo do impedimento", %w[em_atendimento], "impedido", :ban),
        Acao.new("concluir", "Concluir atendimento", "Concluir atendimento", true, "Resultado do atendimento",
                 %w[em_atendimento impedido aguardando_solicitante], "concluido", :check_circle),
        Acao.new("liberar", "Liberar chamado", "Liberar chamado para outro profissional", true, "Motivo",
                 %w[em_triagem em_atendimento aguardando_solicitante impedido], "liberado", :reload),
        Acao.new("atribuir", "Atribuir a alguém", "Atribuir chamado", true, "Motivo da atribuição",
                 %w[aberto em_triagem aguardando_tecnico em_atendimento aguardando_solicitante impedido], "atribuido", :people),
        Acao.new("reabrir", "Reabrir chamado", "Reabrir chamado", true, "Motivo da reabertura", %w[concluido], "reaberto", :reload),
        Acao.new("prioridade", "Mudar prioridade", "Mudar prioridade", true, "Motivo",
                 %w[aberto em_triagem aguardando_tecnico em_atendimento aguardando_solicitante impedido], "prioridade_alterada", :warning)
      ].index_by(&:chave).freeze

      def self.call(...) = new(...).call

      # As ações que o usuário pode fazer agora neste chamado (para montar os botões).
      def self.disponiveis(chamado, ator) = ACOES.values.select { |acao| new(chamado:, acao: acao.chave, ator:).permitida? }

      def initialize(chamado:, acao:, ator:, nota: nil, alvo: nil, prioridade: nil)
        @chamado = chamado
        @acao = ACOES[acao.to_s]
        @ator = ator
        @nota = nota.to_s.squish.presence
        @alvo = alvo
        @prioridade = prioridade.to_s
      end

      def call
        return falha("A ação informada não é válida.") unless @acao
        return falha("Você não pode fazer isso neste chamado.") unless permitida?
        return falha("#{@acao.rotulo_nota} deve ser preenchido.") if @acao.pede_nota && @nota.nil?

        de = @chamado.status
        send(:"fazer_#{@acao.chave}") # muda o chamado e define @texto_do_evento, ou define @erro
        return falha(@erro) if @erro

        Ti::Chamado.transaction do
          @chamado.save!
          @chamado.eventos.create!(tipo: @acao.evento, de_status: de, para_status: @chamado.status, nota: @texto_do_evento, ator: @ator,
                                   ator_nome: @ator.nome, ocorrido_em: Time.current)
          Core::Api.auditar(evento: "ti.chamado.#{@acao.evento}", alvo: @chamado, ator: @ator,
                            dados: { codigo: @chamado.codigo, de: de, para: @chamado.status, nota: @nota }.compact)
        end
        Conversa.sincronizar(@chamado, nota: nota_da_conversa)
        Avisos.depois_de(@chamado, acao: @acao.chave, de: de, ator: @ator, nota: @nota)
        Core::Resultado.sucesso(@chamado)
      end

      def permitida?
        return false unless @acao && @acao.de.include?(@chamado.status) && Acesso.pode_operar?(@ator, @chamado)

        supervisao = Acesso.supervisiona?(@ator)
        case @acao.chave
        when "assumir" then pode_assumir?(supervisao)
        when "encaminhar" then supervisao || (Acesso.triador?(@ator) && [ nil, @ator.id ].include?(@chamado.triador_id) && @chamado.responsavel_id.nil?)
        when "devolver" then supervisao || do_responsavel? || (@chamado.em_triagem? && do_triador?)
        when "impedir", "concluir" then supervisao || do_responsavel?
        when "liberar" then supervisao || do_responsavel? || (@chamado.em_triagem? && do_triador?)
        when "atribuir", "reabrir" then supervisao
        when "prioridade" then supervisao || do_responsavel? || do_triador?
        end
      end

      private

      # O que aparece na conversa do chamado, para o solicitante entender o que mudou.
      def nota_da_conversa
        case @acao.chave
        when "assumir", "atribuir"
          profissional = @chamado.em_triagem? ? @chamado.triador : @chamado.responsavel
          "#{profissional.nome} assumiu o chamado#{@chamado.em_triagem? ? ' e iniciou a triagem' : ''}. Use esta conversa para falar com #{profissional.nome.split.first.capitalize}."
        when "concluir" then "Atendimento concluído: #{@nota} Esta conversa fica só para consulta."
        else @texto_do_evento
        end
      end

      def do_responsavel? = @chamado.responsavel_id == @ator.id
      def do_triador? = @chamado.triador_id == @ator.id

      def pode_assumir?(supervisao)
        return false if do_responsavel? || (@chamado.em_triagem? && do_triador? && !Acesso.atende?(@ator))
        return supervisao if @chamado.responsavel_id.present? # já tem dono: só a supervisão toma para si
        return false unless Acesso.pode_assumir_sozinho?(@ator, @chamado)

        vai_triar?(@ator) || Acesso.atende?(@ator)
      end

      # Solicitação com triagem, ainda não triada, pega por um triador: entra em triagem.
      def vai_triar?(user) = @chamado.problema.exige_triagem? && @chamado.aberto? && Acesso.triador?(user)

      def fazer_assumir = entregar_a(@ator, "Chamado assumido")

      def fazer_atribuir
        return @erro = "Escolha para quem atribuir." unless @alvo
        return @erro = "A pessoa escolhida não faz parte dos grupos técnicos desta solicitação." unless Acesso.operadores_do(@chamado).exists?(id: @alvo.id)

        entregar_a(@alvo, "#{@nota} Atribuído por #{@ator.nome}")
      end

      def entregar_a(user, inicio)
        if vai_triar?(user)
          @chamado.assign_attributes(status: "em_triagem", triador: user, triado_em: Time.current, responsavel: nil)
          @texto_do_evento = "#{inicio} para triagem por #{user.nome}."
        elsif Acesso.atende?(user)
          pulou = @chamado.problema.exige_triagem? && @chamado.triador_id.nil?
          @chamado.assign_attributes(status: "em_atendimento", responsavel: user)
          @texto_do_evento = "#{inicio} para atendimento por #{user.nome}.#{' A etapa de triagem foi pulada.' if pulou}"
        else
          @erro = "#{user.nome} só faz triagem, e este chamado já passou dessa etapa."
        end
      end

      def fazer_encaminhar
        @chamado.assign_attributes(status: "aguardando_tecnico", triador: @ator, triado_em: Time.current, nota_triagem: @nota, responsavel: nil)
        @texto_do_evento = "Triagem concluída: #{@nota}"
      end

      def fazer_devolver
        @chamado.assign_attributes(status: "aguardando_solicitante", nota_triagem: @nota)
        @texto_do_evento = "Ajuste pedido ao solicitante: #{@nota}"
      end

      def fazer_impedir
        @chamado.assign_attributes(status: "impedido", nota_triagem: @nota)
        @texto_do_evento = "Atendimento impedido: #{@nota}"
      end

      def fazer_concluir
        @chamado.assign_attributes(status: "concluido", concluido_em: Time.current, responsavel: @chamado.responsavel || @ator)
        @texto_do_evento = "Atendimento concluído: #{@nota}"
      end

      # Sem responsável de novo, para outro profissional pegar.
      def fazer_liberar
        triar = @chamado.problema.exige_triagem? && @chamado.triado_em.nil?
        @chamado.assign_attributes(status: (triar ? "aberto" : "aguardando_tecnico"), responsavel: nil, triador: (triar ? nil : @chamado.triador))
        @texto_do_evento = "Chamado liberado por #{@ator.nome}: #{@nota}"
      end

      def fazer_reabrir
        @chamado.assign_attributes(status: (@chamado.responsavel ? "em_atendimento" : "aguardando_tecnico"), concluido_em: nil)
        @texto_do_evento = "Chamado reaberto pela supervisão: #{@nota}"
      end

      def fazer_prioridade
        return @erro = "Escolha a nova prioridade." unless Ti::Problema::PRIORIDADES.key?(@prioridade)
        return @erro = "O chamado já está com essa prioridade." if @prioridade == @chamado.prioridade

        anterior = @chamado.nome_da_prioridade
        @chamado.prioridade = @prioridade
        @texto_do_evento = "Prioridade alterada de #{anterior} para #{@chamado.nome_da_prioridade}: #{@nota}"
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @chamado)
    end
  end
end
