module Transporte
  module SolicitacoesHelper
    TONS = { "solicitada" => :info, "aprovada" => :sucesso, "reagendada" => :atencao, "em_servico" => :sucesso, "busca" => :atencao, "concluida" => :neutro, "cancelada" => :atencao }.freeze

    def selo_da_solicitacao(solicitacao)
      render "compartilhado/selo", texto: solicitacao.nome_do_status, tom: TONS.fetch(solicitacao.status, :neutro)
    end

    def data_e_hora(valor) = valor ? l(valor, format: "%d/%m/%Y %H:%M") : nil
  end
end
