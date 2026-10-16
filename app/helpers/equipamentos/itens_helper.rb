module Equipamentos
  module ItensHelper
    TONS_DO_STATUS = { "ativo" => :sucesso, "inativo" => :neutro, "em_manutencao" => :atencao, "descartado" => :neutro }.freeze
    TONS_DA_SITUACAO = { "disponivel" => :neutro, "em_movimentacao" => :info, "emprestado" => :atencao }.freeze
    TONS_DO_ENVIO = { "em_andamento" => :info, "concluida" => :sucesso, "cancelada" => :neutro }.freeze
    TONS_DA_LINHA = { "pendente" => :info, "recebido" => :sucesso, "emprestado" => :atencao, "devolucao_pendente" => :info, "devolvido" => :sucesso, "cancelado" => :neutro }.freeze

    def selo_do_equipamento(item) = render("compartilhado/selo", texto: item.nome_do_status, tom: TONS_DO_STATUS.fetch(item.status, :neutro))
    def selo_do_envio(envio) = render("compartilhado/selo", texto: envio.nome_do_status, tom: TONS_DO_ENVIO.fetch(envio.status, :neutro))
    def selo_da_linha(linha) = render("compartilhado/selo", texto: linha.nome_do_status, tom: TONS_DA_LINHA.fetch(linha.status, :neutro))

    # Onde o equipamento está agora, quando não está livre: indo para outra unidade, ou emprestado.
    def selo_da_disponibilidade(item)
      return if item.disponivel?

      render "compartilhado/selo", texto: item.nome_da_situacao, tom: TONS_DA_SITUACAO.fetch(item.situacao, :neutro)
    end

    # Empréstimo com a devolução vencida: em vermelho, com os dias.
    def selo_de_atraso(envio)
      dias = envio.dias_de_atraso
      return unless dias.positive?

      tag.span("Atrasado #{dias} dia#{'s' if dias > 1}", class: "inline-flex rounded-full border border-[var(--danger-border-strong)] bg-[var(--danger-surface)] px-2 py-0.5 text-[11px] font-semibold text-[var(--danger-text)]")
    end
  end
end
