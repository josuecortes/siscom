module Transporte
  # Configurações do módulo (porta das colunas transport_* de system_setting.rb do seed).
  # Existe uma única linha; use Transporte::Configuracao.atual.
  class Configuracao < ApplicationRecord
    self.table_name = "transporte_configuracoes"

    include SenhaDoPainel

    # [mínimo, máximo] de cada faixa; o mínimo não pode passar do máximo.
    FAIXAS = { normal_antecedencia: "horas", viagem_antecedencia: "horas", espera: "horas", busca: "horas" }.freeze
    CAMPOS = (FAIXAS.keys.flat_map { |faixa| [ :"#{faixa}_min_horas", :"#{faixa}_max_horas" ] } +
              %i[lembrete_saida_minutos aviso_busca_atrasada_minutos]).freeze

    validates :normal_antecedencia_min_horas, :viagem_antecedencia_min_horas, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :normal_antecedencia_max_horas, :viagem_antecedencia_max_horas, :espera_min_horas, :espera_max_horas, :busca_min_horas, :busca_max_horas,
              :lembrete_saida_minutos, :aviso_busca_atrasada_minutos, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validate :minimo_ate_o_maximo

    def self.atual = first || create!

    private

    def minimo_ate_o_maximo
      FAIXAS.each_key do |faixa|
        minimo, maximo = self[:"#{faixa}_min_horas"], self[:"#{faixa}_max_horas"]
        errors.add(:"#{faixa}_max_horas", "deve ser maior ou igual ao mínimo") if minimo && maximo && maximo < minimo
      end
    end
  end
end
