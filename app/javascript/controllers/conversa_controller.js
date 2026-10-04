import { Controller } from "@hotwired/stimulus"

// Conversa: mantém a lista rolada até a última mensagem (ao abrir e quando chega uma nova por
// Turbo Streams) e envia com Enter (Shift+Enter quebra a linha).
export default class extends Controller {
  static targets = ["lista"]

  connect() {
    this.descer()
    this.observador = new MutationObserver(() => this.descer())
    this.observador.observe(this.listaTarget, { childList: true })
  }

  disconnect() {
    this.observador?.disconnect()
  }

  descer() {
    this.listaTarget.scrollTop = this.listaTarget.scrollHeight
  }

  // O campo é permanente (a página se atualiza sozinha e não pode apagar o que está sendo digitado),
  // então quem limpa depois de um envio que deu certo é este controller.
  limpar(evento) {
    if (!evento.detail.success) return
    const campo = this.element.querySelector("textarea")
    if (campo) { campo.value = ""; campo.focus() }
  }

  enviarComEnter(evento) {
    if (evento.shiftKey) return
    evento.preventDefault()
    if (evento.target.value.trim() !== "") evento.target.form.requestSubmit()
  }
}
