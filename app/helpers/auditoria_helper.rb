# Apresentação dos registros de auditoria.
module AuditoriaHelper
  # Resumo legível dos dados do registro ("nome: A → B", "Administração · Auditor").
  def detalhes_da_auditoria(registro)
    dados = registro.dados
    partes = []

    dados.fetch("mudancas", {}).each do |campo, mudanca|
      partes << "#{User.human_attribute_name(campo)}: #{mudanca['de'].presence || '—'} → #{mudanca['para'].presence || '—'}"
    end

    if dados["modulo"]
      modulo = Core::Catalogo.modulo(dados["modulo"])
      papel = modulo&.papel(dados["papel"])&.nome || dados["papel"]
      partes << [ modulo&.nome || dados["modulo"], papel ].compact.join(" · ")
    end

    partes << dados["email"] if dados["email"]
    partes << "troca obrigatória" if dados["troca_obrigatoria"]
    partes.join("; ")
  end
end
