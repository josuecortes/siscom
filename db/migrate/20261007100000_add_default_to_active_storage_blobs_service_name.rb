# Contingência da virada (docs/refactor-remaster/07-virada-e-contingencia.md): a coluna `service_name` de
# `active_storage_blobs` passou a ser obrigatória nas migrations do Rails novo, mas o siscom antigo (Rails 6.0)
# não a preenche. Com o valor padrão "local", se for preciso voltar o código antigo sobre o banco já migrado,
# o envio de arquivos do sistema antigo continua funcionando. Só acrescenta um valor padrão; não altera dados.
class AddDefaultToActiveStorageBlobsServiceName < ActiveRecord::Migration[8.1]
  def change
    change_column_default :active_storage_blobs, :service_name, from: nil, to: "local"
  end
end
