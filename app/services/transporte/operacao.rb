module Transporte
  # Quem enxerga o quê na Operação. A operação (técnico e administrador) vê todas as solicitações.
  # O motorista é outro ator: vê o que pode pegar (aprovadas e aguardando busca) e aquilo em que trabalhou.
  module Operacao
    OPERAR = "transporte.solicitacoes.operar".freeze
    EXECUTAR = "transporte.servico.executar".freeze
    ABAS_DO_MOTORISTA = %w[aprovada em_servico busca concluida].freeze

    module_function

    def opera?(user) = Core::Autorizacao.new(user).pode?(OPERAR)
    def dirige?(user) = Core::Autorizacao.new(user).pode?(EXECUTAR)

    def visiveis(user)
      return Transporte::Solicitacao.all if opera?(user)
      return do_motorista(user) if dirige?(user)

      Transporte::Solicitacao.none
    end

    def do_motorista(user)
      Transporte::Solicitacao.where(status: %w[aprovada busca]).or(Transporte::Solicitacao.where(id: Transporte::Servico.where(motorista: user).select(:solicitacao_id)))
    end
  end
end
