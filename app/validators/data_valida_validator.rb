# Acusa data digitada que não existe ou está fora do formato (ex.: 31/02/2020, "amanhã").
#   validates :data_nascimento, data_valida: true
class DataValidaValidator < ActiveModel::EachValidator
  def validate_each(registro, atributo, valor)
    digitado = registro.public_send("#{atributo}_before_type_cast")
    return if digitado.blank? || valor.present?

    registro.errors.add(atributo, options[:message] || "não é uma data válida (use dd/mm/aaaa)")
  end
end
