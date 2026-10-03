# Endereço da escola em campos separados (preenchidos pelo CEP), no lugar do texto livre.
class SepararEnderecoEmRhDadosEscola < ActiveRecord::Migration[8.1]
  def change
    change_table :rh_dados_escola, bulk: true do |t|
      t.remove :endereco, type: :text
      t.string :cep
      t.string :logradouro
      t.string :numero
      t.string :complemento
      t.string :bairro
      t.string :cidade
      t.string :uf, limit: 2
    end
  end
end
