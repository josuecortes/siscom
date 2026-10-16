# Datas no formato brasileiro (dd/mm/aaaa) em formulários e filtros.
# O banco continua guardando a data no formato dele; este módulo só cuida da
# entrada e da exibição.
#
#   DataBr.interpretar("15/01/1985")  # => Date 1985-01-15
#   DataBr.interpretar("1985-01-15")  # => Date 1985-01-15 (formato do banco também é aceito)
#   DataBr.interpretar("31/02/2020")  # => nil
#   DataBr.formatar(Date.new(1985, 1, 15))  # => "15/01/1985"
module DataBr
  FORMATO = "%d/%m/%Y".freeze
  PADRAO_BR = %r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}
  PADRAO_ISO = /\A(\d{4})-(\d{1,2})-(\d{1,2})\z/

  module_function

  def interpretar(valor)
    return valor.to_date if valor.respond_to?(:to_date) && !valor.is_a?(String)

    texto = valor.to_s.strip
    if (partes = texto.match(PADRAO_BR))
      dia, mes, ano = partes.captures.map(&:to_i)
    elsif (partes = texto.match(PADRAO_ISO))
      ano, mes, dia = partes.captures.map(&:to_i)
    else
      return nil
    end

    Date.valid_date?(ano, mes, dia) ? Date.new(ano, mes, dia) : nil
  end

  # Aceita Date/Time ou texto (devolve o texto como veio quando não é uma data válida,
  # para o formulário mostrar de volta o que o usuário digitou).
  def formatar(valor)
    return "" if valor.blank?

    data = interpretar(valor)
    data ? data.strftime(FORMATO) : valor.to_s
  end

  # Tipo de atributo, aplicado por `datas_br :data_nascimento` no model.
  class Tipo < ActiveRecord::Type::Date
    def cast(valor)
      valor.is_a?(String) ? DataBr.interpretar(valor) : super
    end
  end
end
