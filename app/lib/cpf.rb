# CPF: só os dígitos, conferência dos dígitos verificadores e formato 000.000.000-00.
module Cpf
  module_function

  def digitos(valor) = valor.to_s.gsub(/\D/, "")

  def valido?(valor)
    cpf = digitos(valor)
    return false unless cpf.length == 11 && cpf.chars.uniq.size > 1

    numeros = cpf.chars.map(&:to_i)
    [ 9, 10 ].all? do |posicao|
      soma = numeros.first(posicao).each_with_index.sum { |numero, indice| numero * (posicao + 1 - indice) }
      (soma * 10 % 11 % 10) == numeros[posicao]
    end
  end

  def formatar(valor)
    cpf = digitos(valor)
    cpf.length == 11 ? "#{cpf[0, 3]}.#{cpf[3, 3]}.#{cpf[6, 3]}-#{cpf[9, 2]}" : valor.to_s
  end
end
