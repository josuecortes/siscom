module Legado
  # Base dos models do legado: qualquer tentativa de gravar falha.
  class Registro < ApplicationRecord
    self.abstract_class = true

    def readonly? = true

    def self.delete_all(*) = raise(ActiveRecord::ReadOnlyRecord, "#{name} é somente leitura")
    def self.update_all(*) = raise(ActiveRecord::ReadOnlyRecord, "#{name} é somente leitura")
    def self.insert_all(*, **) = raise(ActiveRecord::ReadOnlyRecord, "#{name} é somente leitura")
    def self.upsert_all(*, **) = raise(ActiveRecord::ReadOnlyRecord, "#{name} é somente leitura")
  end
end
