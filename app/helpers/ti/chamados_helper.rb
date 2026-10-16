module Ti
  module ChamadosHelper
    # Cores do seed (renderTicketStatus em helpdesk-tickets-module.tsx): os demais status ficam neutros.
    TONS_DO_STATUS = { "aberto" => :aberto, "aguardando_tecnico" => :aguardando, "em_atendimento" => :andamento, "concluido" => :sucesso }.freeze

    # Selo "Liberado N×": o chamado já esteve com alguém e foi devolvido; quem pode pegar deve olhar primeiro.
    def selo_de_liberado(liberacoes)
      return unless liberacoes

      vezes = liberacoes.vezes == 1 ? "1 vez" : "#{liberacoes.vezes} vezes"
      tag.span(class: "inline-flex items-center gap-1 rounded-full border border-[var(--warning-solid)] bg-[var(--warning-surface)] px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.06em] text-[var(--warning-text)]",
               title: "Estava sendo atendido e foi liberado #{vezes}. Última: #{liberacoes.por} em #{l(liberacoes.em, format: '%d/%m/%Y %H:%M')}.") do
        safe_join([ icone(:reload, classe: "h-3 w-3"), "Liberado #{liberacoes.vezes}×" ])
      end
    end

    def selo_do_status(chamado)
      render "compartilhado/selo", texto: chamado.nome_do_status, tom: TONS_DO_STATUS.fetch(chamado.status, :neutro)
    end
  end
end
