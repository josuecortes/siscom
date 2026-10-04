module Ti
  module ChamadosHelper
    TONS_DO_STATUS = { "concluido" => :sucesso, "finalizado" => :sucesso, "aguardando_solicitante" => :atencao, "impedido" => :atencao,
                       "cancelado" => :atencao }.freeze

    def selo_do_status(chamado)
      render "compartilhado/selo", texto: chamado.nome_do_status, tom: TONS_DO_STATUS.fetch(chamado.status, :neutro)
    end
  end
end
