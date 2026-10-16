module Transporte
  module SolicitacoesHelper
    TONS = { "solicitada" => :info, "aprovada" => :sucesso, "reagendada" => :atencao, "em_servico" => :sucesso, "busca" => :atencao, "concluida" => :neutro, "cancelada" => :atencao }.freeze

    def selo_da_solicitacao(solicitacao)
      render "compartilhado/selo", texto: solicitacao.nome_do_status, tom: TONS.fetch(solicitacao.status, :neutro)
    end

    # Normal ou viagem, para bater o olho na lista: a viagem (fora da cidade) vem destacada, com ícone.
    def selo_do_tipo(solicitacao)
      if solicitacao.viagem?
        tag.span(class: "inline-flex items-center gap-1 rounded-full bg-[var(--info-badge-surface)] px-2.5 py-1 text-xs font-semibold uppercase tracking-[0.08em] text-[var(--info-badge-text)]") do
          safe_join([ icone(:location_pin, classe: "h-3.5 w-3.5"), "Viagem" ])
        end
      else
        render "compartilhado/selo", texto: "Normal", tom: :neutro
      end
    end

    def data_e_hora(valor) = valor ? l(valor, format: "%d/%m/%Y %H:%M") : nil
  end
end
