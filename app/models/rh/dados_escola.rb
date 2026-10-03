module Rh
  # Dados que só as escolas têm (porta de school_detail.rb): NAE, código INEP, endereço.
  class DadosEscola < ApplicationRecord
    self.table_name = "rh_dados_escola"

    belongs_to :unidade, class_name: "Rh::Unidade", inverse_of: :dados_escola

    normalizes :cep, with: ->(cep) { cep.to_s.gsub(/\D/, "").presence }
    normalizes :uf, with: ->(uf) { uf.to_s.strip.upcase.presence }

    validates :unidade_id, uniqueness: true
    validates :cep, length: { is: 8, message: "deve ter 8 dígitos" }, allow_nil: true

    # "Rua A, 10, Sala 2 - Centro - Macapá/AP - CEP 68900-073"
    def endereco_completo
      rua = [ logradouro, numero, complemento ].compact_blank.join(", ")
      cidade_uf = [ cidade, uf ].compact_blank.join("/")
      cep_formatado = cep.present? ? "CEP #{cep[0, 5]}-#{cep[5, 3]}" : nil
      [ rua, bairro, cidade_uf, cep_formatado ].compact_blank.join(" - ")
    end
    validate :unidade_e_escola

    private

    def unidade_e_escola
      errors.add(:unidade, "deve ser uma escola") if unidade && !unidade.escola?
    end
  end
end
