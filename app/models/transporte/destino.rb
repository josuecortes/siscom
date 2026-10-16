module Transporte
  # Destino de uma solicitação de transporte: endereço (pelo CEP ou pelo mapa) e, quando houver, o ponto no mapa.
  class Destino < ApplicationRecord
    self.table_name = "transporte_destinos"

    belongs_to :solicitacao, class_name: "Transporte::Solicitacao", inverse_of: :destinos

    normalizes :nome, :logradouro, :numero, :bairro, :cidade, with: ->(texto) { texto.to_s.squish }
    normalizes :uf, with: ->(uf) { uf.to_s.strip.upcase }
    normalizes :cep, with: ->(cep) { Cpf.digitos(cep).then { |d| d.length == 8 ? "#{d[0, 5]}-#{d[5, 3]}" : nil } }

    validates :nome, :logradouro, :numero, :bairro, :cidade, presence: true, length: { maximum: 200 }
    validates :uf, format: { with: /\A[A-Z]{2}\z/, message: "deve ter 2 letras" }
    validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
    validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

    def endereco = "#{logradouro}, #{numero} - #{bairro}, #{cidade}/#{uf}"
    def no_mapa? = latitude.present? && longitude.present?
  end
end
