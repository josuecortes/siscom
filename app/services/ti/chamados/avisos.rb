module Ti
  module Chamados
    # Notificações e atualização das telas depois de cada mudança no chamado (regras do
    # tickets_controller do seed: quem só "pode pegar" é avisado enquanto o chamado está sem dono;
    # depois, só o solicitante e o responsável).
    module Avisos
      module_function

      def depois_de(chamado, acao:, de:, ator:, nota: nil)
        codigo = chamado.codigo
        case acao
        when "assumir"
          notificar([ chamado.solicitante ], chamado, ator, "requisitante",
                    chamado.em_triagem? ? "Chamado em triagem" : "Chamado em atendimento",
                    chamado.em_triagem? ? "#{codigo} entrou em triagem." : "#{codigo} agora está em atendimento.")
        when "atribuir"
          notificar([ chamado.responsavel || chamado.triador ], chamado, ator, "operacao", "Chamado atribuído a você", "#{codigo} foi encaminhado para você. #{nota}")
        when "encaminhar", "liberar"
          tecnicos = Acesso.operadores_do(chamado).select { |user| Acesso.atende?(user) }
          destinatarios = chamado.aberto? || tecnicos.empty? ? Acesso.operadores_do(chamado).to_a : tecnicos
          notificar(destinatarios, chamado, ator, "operacao", "Chamado aguardando atendimento", "#{codigo} está disponível para atendimento.")
        when "devolver"
          notificar([ chamado.solicitante ], chamado, ator, "requisitante", "Chamado precisa da sua atenção", "#{codigo} precisa de ajustes. #{nota}")
        when "concluir"
          notificar([ chamado.solicitante ], chamado, ator, "requisitante", "Chamado concluído", "#{codigo} foi concluído.")
        when "reabrir"
          notificar([ chamado.solicitante ], chamado, ator, "requisitante", "Chamado reaberto", "#{codigo} foi reaberto para atendimento.")
          notificar([ chamado.responsavel ], chamado, ator, "operacao", "Chamado reaberto", "#{codigo} voltou para atendimento. #{nota}")
        when "impedir"
          notificar([ chamado.solicitante ], chamado, ator, "requisitante", "Chamado com impedimento", "#{codigo} está impedido. #{nota}")
        when "responder"
          notificar([ chamado.responsavel, chamado.triador ].compact.presence || Acesso.operadores_do(chamado).to_a, chamado, ator, "operacao",
                    "Chamado respondido pelo solicitante", "#{codigo} voltou para a operação.")
        end
        atualizar_telas(chamado)
      end

      def notificar(destinatarios, chamado, ator, lado, titulo, mensagem)
        destinatarios = Array(destinatarios).compact.uniq - [ ator ]
        return if destinatarios.empty?

        rotas = Rails.application.routes.url_helpers
        url = lado == "requisitante" ? rotas.ti_chamado_path(chamado) : rotas.ti_operacao_path(chamado)
        Core::Api.notificar(destinatarios: destinatarios, evento: "ti.chamado.#{chamado.status}", titulo: titulo, mensagem: mensagem.squish,
                            url_acao: url, alvo: chamado, ator: ator)
      end

      # Quem está com a lista da operação, com o chamado ou com "Meus chamados" aberto vê a mudança na hora.
      def atualizar_telas(chamado)
        # Sem request_id: o Turbo junta os pedidos de atualização próximos e fica com o último; se o último
        # trouxesse o id da própria requisição, o navegador de quem fez a ação o ignoraria e a tela não mudaria.
        [ "ti_operacao", chamado, [ chamado.solicitante, "ti_chamados" ] ].each do |canal|
          Turbo::StreamsChannel.broadcast_refresh_to(*Array(canal), request_id: nil)
        end
      end
    end
  end
end
