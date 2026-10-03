module Rh
  # Pendência deixada pela importação do siscom antigo, ligada à pessoa.
  class PendenciaImportacao < ApplicationRecord
    self.table_name = "rh_pendencias_importacao"

    TIPOS = {
      "cpf_vazio" => "CPF não informado",
      "cpf_invalido" => "CPF inválido",
      "cpf_repetido" => "CPF repetido em outra pessoa",
      "nome_sem_sobrenome" => "Nome sem sobrenome",
      "sem_lotacao" => "Sem unidade ou função para lotar"
    }.freeze

    belongs_to :pessoa, class_name: "Rh::Pessoa", optional: true

    validates :tipo, inclusion: { in: TIPOS.keys }
    validates :descricao, presence: true

    scope :abertas, -> { where(resolvida_em: nil) }

    def rotulo = TIPOS.fetch(tipo)
  end
end
