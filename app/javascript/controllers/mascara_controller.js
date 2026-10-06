import { Controller } from "@hotwired/stimulus"

// Máscaras de digitação: data (dd/mm/aaaa), hora, data e hora, CPF, CNPJ, CEP, celular e telefone.
//   data-controller="mascara" data-mascara-tipo-value="data" data-action="input->mascara#aplicar"
//
// Campos de data e de data e hora ganham também um botão de calendário (padrão do sistema): ele abre o
// seletor do próprio navegador (com a hora, quando o campo tem hora) e escreve a escolha no campo, já no
// formato brasileiro. Digitar continua valendo: o calendário é só um atalho.
const ICONE_DO_CALENDARIO =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4" aria-hidden="true">' +
  '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/></svg>'

export default class extends Controller {
  static values = { tipo: String }

  connect() {
    if (this.element.value) this.aplicar()
    if (this.comCalendario) this.montarCalendario()
  }

  disconnect() {
    this.botao?.remove()
    this.nativo?.remove()
    this.botao = this.nativo = null
  }

  get comCalendario() {
    return ["data", "data_hora"].includes(this.tipoValue) && !this.element.readOnly && !this.element.disabled
  }

  // O campo é embrulhado uma vez (o embrulho fica); o botão e o seletor do navegador entram ao lado dele.
  montarCalendario() {
    let caixa = this.element.parentElement
    if (!caixa.dataset.calendario) {
      caixa = document.createElement("span")
      caixa.dataset.calendario = "1"
      caixa.className = "relative block"
      this.element.before(caixa)
      caixa.append(this.element) // mover o campo reconecta este controller; o botão é criado nessa segunda vez
      return
    }
    if (caixa.querySelector("button[data-calendario-botao]")) return

    this.element.style.paddingRight = "2.75rem"
    this.nativo = document.createElement("input")
    this.nativo.type = this.tipoValue === "data" ? "date" : "datetime-local"
    this.nativo.tabIndex = -1
    this.nativo.setAttribute("aria-hidden", "true")
    this.nativo.dataset.calendarioNativo = "1"
    this.nativo.className = "pointer-events-none absolute bottom-0 right-0 h-0 w-0 border-0 p-0 opacity-0"
    this.nativo.addEventListener("change", () => this.escolher())

    this.botao = document.createElement("button")
    this.botao.type = "button"
    this.botao.dataset.calendarioBotao = "1"
    this.botao.title = this.tipoValue === "data" ? "Abrir calendário" : "Abrir calendário e hora"
    this.botao.setAttribute("aria-label", this.botao.title)
    this.botao.className =
      "absolute inset-y-0 right-0 inline-flex w-11 cursor-pointer items-center justify-center rounded-r-xl text-[var(--text-secondary)] hover:text-[var(--accent-strong)]"
    this.botao.innerHTML = ICONE_DO_CALENDARIO
    this.botao.addEventListener("click", () => this.abrirCalendario())
    caixa.append(this.nativo, this.botao)
  }

  abrirCalendario() {
    this.nativo.value = this.paraNativo(this.element.value)
    try {
      this.nativo.showPicker()
    } catch {
      this.nativo.focus() // navegador sem showPicker: o foco já abre o seletor na maioria deles
      this.nativo.click()
    }
  }

  // Escreve a escolha no campo e avisa quem escuta (filtros que aplicam sozinhos, validações).
  escolher() {
    if (!this.nativo.value) return
    const [data, hora] = this.nativo.value.split("T")
    const [ano, mes, dia] = data.split("-")
    this.element.value = hora ? `${dia}/${mes}/${ano} ${hora.slice(0, 5)}` : `${dia}/${mes}/${ano}`
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
    this.element.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // "15/01/2026 09:30" -> "2026-01-15T09:30" (vazio quando ainda não é uma data completa).
  paraNativo(texto) {
    const partes = texto.match(/^(\d{2})\/(\d{2})\/(\d{4})(?: (\d{2}):(\d{2}))?$/)
    if (!partes) return ""
    const data = `${partes[3]}-${partes[2]}-${partes[1]}`
    if (this.tipoValue === "data") return data
    return `${data}T${partes[4] || "08"}:${partes[5] || "00"}`
  }

  aplicar() {
    const digitos = this.element.value.replace(/\D/g, "")
    // Nomes com prefixo: `this.data` já é usado pelo Stimulus.
    const formatar = {
      data: this.mascaraData, cpf: this.mascaraCpf, telefone: this.mascaraTelefone, celular: this.mascaraTelefone,
      hora: this.mascaraHora, data_hora: this.mascaraDataHora, cnpj: this.mascaraCnpj, cep: this.mascaraCep
    }[this.tipoValue]
    if (!formatar) return
    const formatado = formatar(digitos)
    if (formatado !== this.element.value) this.element.value = formatado
  }

  mascaraData(d) {
    return [d.slice(0, 2), d.slice(2, 4), d.slice(4, 8)].filter(Boolean).join("/")
  }

  mascaraHora(d) {
    return [d.slice(0, 2), d.slice(2, 4)].filter(Boolean).join(":")
  }

  mascaraDataHora(d) {
    const data = [d.slice(0, 2), d.slice(2, 4), d.slice(4, 8)].filter(Boolean).join("/")
    const hora = [d.slice(8, 10), d.slice(10, 12)].filter(Boolean).join(":")
    return hora ? `${data} ${hora}` : data
  }

  mascaraCnpj(d) {
    const partes = [d.slice(0, 2), d.slice(2, 5), d.slice(5, 8)].filter(Boolean).join(".")
    return partes + (d.length > 8 ? "/" + d.slice(8, 12) : "") + (d.length > 12 ? "-" + d.slice(12, 14) : "")
  }

  mascaraCep(d) {
    return d.length > 5 ? `${d.slice(0, 5)}-${d.slice(5, 8)}` : d
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
