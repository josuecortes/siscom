class AddCamposDocumentosToTransportador < ActiveRecord::Migration[6.0]
  def change
    add_column :transporte_escolar_transportadores, :doc_rg, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_cpf, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_carteira_maritima, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_dpen, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_tie, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_comprovante_endereco_contrato, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_certidao_negativa_estadual, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_certidao_negativa_federal, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_fotos_atualizadas, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_relacao_dos_alunos_por_rota, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_comprovante_conta_bancaria, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_cnh_categoria_d, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_auto_de_trafego, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_crlv, :boolean, default: false
    add_column :transporte_escolar_transportadores, :doc_certificado_curso_de_condutor_escolar, :boolean, default: false
  end
end
