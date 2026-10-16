module Ti
  module Chamados
    # A conversa do chamado (regras de sync_helpdesk_ticket_service.rb do seed): começa quando
    # alguém assume; fica ativa em triagem, ajuste, aguardando técnico, em trabalho e impedido;
    # participam o solicitante e UM profissional por vez (o triador durante a triagem, depois o
    # responsável); concluído, finalizado ou cancelado, fica só para leitura.
    module Conversa
      ATIVA_EM = %w[em_triagem aguardando_solicitante aguardando_tecnico em_atendimento impedido].freeze
      ENCERRADA = "O chamado foi encerrado. Esta conversa fica só para consulta.".freeze

      module_function

      def sincronizar(chamado, nota: nil)
        ativa = ATIVA_EM.include?(chamado.status)
        return unless ativa || Core::Api.conversa_de(chamado) # chamado que ninguém assumiu não tem conversa

        rotas = Rails.application.routes.url_helpers
        profissional = chamado.em_triagem? ? chamado.triador : (chamado.responsavel || chamado.triador)
        Core::Api.sincronizar_conversa(
          alvo: chamado, modulo: :ti, titulo: "#{chamado.codigo} · #{chamado.problema.nome}", ativa: ativa,
          motivo_leitura: (ENCERRADA unless ativa), nota_do_sistema: nota,
          participantes: [ { user: chamado.solicitante, papel: "solicitante", url: rotas.ti_chamado_path(chamado) },
                           { user: profissional, papel: (chamado.em_triagem? ? "triador" : "tecnico"), url: rotas.ti_operacao_path(chamado) } ]
        )
      end
    end
  end
end
