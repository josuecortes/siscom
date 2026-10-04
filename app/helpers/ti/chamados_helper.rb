module Ti
  module ChamadosHelper
    # Cores do seed (renderTicketStatus em helpdesk-tickets-module.tsx): os demais status ficam neutros.
    TONS_DO_STATUS = { "aberto" => :aberto, "aguardando_tecnico" => :aguardando, "em_atendimento" => :andamento, "concluido" => :sucesso }.freeze

    def selo_do_status(chamado)
      render "compartilhado/selo", texto: chamado.nome_do_status, tom: TONS_DO_STATUS.fetch(chamado.status, :neutro)
    end
  end
end
