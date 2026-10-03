import { Controller } from "@hotwired/stimulus"

// Máscaras de digitação: data (dd/mm/aaaa), CPF (000.000.000-00) e telefone ((00) 00000-0000).
//   data-controller="mascara" data-mascara-tipo-value="data" data-action="input->mascara#aplicar"
export default class extends Controller {
  static values = { tipo: String }

  connect() {
    if (this.element.value) this.aplicar()
  }

  aplicar() {
    const digitos = this.element.value.replace(/\D/g, "")
    // Nomes com prefixo: `this.data` já é usado pelo Stimulus.
    const formatar = { data: this.mascaraData, cpf: this.mascaraCpf, telefone: this.mascaraTelefone }[this.tipoValue]
    if (!formatar) return
    const formatado = formatar(digitos)
    if (formatado !== this.element.value) this.element.value = formatado
  }

  mascaraData(d) {
    return [d.slice(0, 2), d.slice(2, 4), d.slice(4, 8)].filter(Boolean).join("/")
  }

  mascaraCpf(d) {
    d = d.slice(0, 11)
    return d.replace(/^(\d{3})(\d)/, "$1.$2").replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3").replace(/\.(\d{3})(\d{1,2})$/, ".$1-$2")
  }

  mascaraTelefone(d) {
    d = d.slice(0, 11)
    if (d.length <= 2) return d.replace(/^(\d{1,2})/, "($1")
    if (d.length <= 10) return d.replace(/^(\d{2})(\d{0,4})(\d{0,4})/, (_, a, b, c) => `(${a}) ${b}${c ? "-" + c : ""}`)
    return d.replace(/^(\d{2})(\d{5})(\d{4})/, "($1) $2-$3")
  }
}
