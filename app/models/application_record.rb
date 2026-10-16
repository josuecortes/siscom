class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Datas digitadas no formato brasileiro (dd/mm/aaaa), com validação de data inexistente.
  #   datas_br :data_nascimento, :data_admissao
  def self.datas_br(*atributos)
    atributos.each do |atributo|
      attribute atributo, DataBr::Tipo.new
      validates atributo, data_valida: true
    end
  end
end
