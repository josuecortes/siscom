class AddCamposBancoToTransportador < ActiveRecord::Migration[6.0]
  def change
    add_column :transporte_escolar_transportadores, :codigo, :string
    add_column :transporte_escolar_transportadores, :banco, :string
    add_column :transporte_escolar_transportadores, :agencia, :string
    add_column :transporte_escolar_transportadores, :tipo_de_conta, :integer
    add_column :transporte_escolar_transportadores, :conta, :string
  end
end
