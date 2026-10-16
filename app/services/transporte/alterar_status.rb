module Transporte
  # Ativa ou desativa um motorista ou um veículo (inativo some das opções, mas fica no histórico).
  class AlterarStatus
    PERMISSOES = { "Transporte::Motorista" => "transporte.motoristas.gerenciar", "Transporte::Veiculo" => "transporte.veiculos.gerenciar" }.freeze

    def self.call(...) = new(...).call

    def initialize(registro:, ativo:, alterado_por:)
      @registro = registro
      @status = ativo ? "ativo" : "inativo"
      @alterado_por = alterado_por
    end

    def call
      unless Core::Autorizacao.new(@alterado_por).pode?(PERMISSOES.fetch(@registro.class.name))
        return Core::Resultado.falha("Você não pode fazer esta alteração.", objeto: @registro)
      end
      return Core::Resultado.sucesso(@registro) if @registro.status == @status

      @registro.update!(status: @status)
      objeto = @registro.is_a?(Transporte::Motorista) ? "motorista" : "veiculo"
      Core::Api.auditar(evento: "transporte.#{objeto}.#{@status == 'ativo' ? 'ativado' : 'desativado'}", alvo: @registro, ator: @alterado_por)
      Core::Resultado.sucesso(@registro)
    end
  end
end
