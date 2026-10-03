# Formatação de dados pessoais para exibição.
module FormatosHelper
  def formatar_cpf(valor)
    digitos = valor.to_s.gsub(/\D/, "")
    return valor.presence unless digitos.length == 11

    digitos.sub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  def formatar_telefone(valor)
    digitos = valor.to_s.gsub(/\D/, "")
    case digitos.length
    when 11 then digitos.sub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
    when 10 then digitos.sub(/(\d{2})(\d{4})(\d{4})/, '(\1) \2-\3')
    else valor.presence
    end
  end
end
