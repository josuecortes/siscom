import { Controller } from "@hotwired/stimulus"

// Conversa: mantém a lista rolada até a última mensagem (ao abrir e quando chega uma nova por
// Turbo Streams), põe as mensagens do próprio usuário à direita (data-minha), avisa o servidor
// que a mensagem nova foi vista e envia com Enter (Shift+Enter quebra a linha).
export default class extends Controller {
  static targets = ["lista"]
  static values = { usuario: String, lida: String }

  connect() {
    this.arrumar()
    this.observador = new MutationObserver((mudancas) => {
      this.arrumar()
      const deOutro = mudancas.some((mudanca) => [...mudanca.addedNodes].some((no) => no.dataset?.autorId && no.dataset.autorId !== this.usuarioValue))
      if (deOutro) this.marcarLida()
    })
    this.observador.observe(this.listaTarget, { childList: true })
  }

  disconnect() {
    this.observador?.disconnect()
  }

  arrumar() {
    if (this.usuarioValue) {
      this.listaTarget.querySelectorAll(`[data-autor-id="${this.usuarioValue}"]`).forEach((mensagem) => { mensagem.dataset.minha = "" })
    }
    this.listaTarget.scrollTop = this.listaTarget.scrollHeight
  }

  // A pessoa está com a conversa aberta: a mensagem que acabou de chegar não conta como não lida.
  marcarLida() {
    if (!this.lidaValue) return
    const token = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.lidaValue, { method: "POST", headers: { "X-CSRF-Token": token, Accept: "text/plain" }, credentials: "same-origin" }).catch(() => {})
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
