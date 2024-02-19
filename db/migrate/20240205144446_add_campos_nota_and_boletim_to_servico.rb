class AddCamposNotaAndBoletimToServico < ActiveRecord::Migration[6.0]
  def change
    add_column :transporte_escolar_servicos, :nota, :boolean, default: false
    add_column :transporte_escolar_servicos, :boletim, :boolean, default: false
  end
end
