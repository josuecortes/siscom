import { Controller } from "@hotwired/stimulus"

// Liga/desliga as notificações push deste aparelho (Web Push).
// O pedido de permissão só acontece quando o usuário toca no botão.
export default class extends Controller {
  static targets = ["estado", "ativar", "desativar"]
  static values = { chave: String, url: String }

  async connect() {
    if (!this.suportado) return this.mostrar("Este navegador não recebe avisos com o sistema fechado.", { ativar: false, desativar: false })
    if (Notification.permission === "denied") return this.mostrarBloqueado()

    const inscricao = await this.inscricaoAtual()
    inscricao ? this.mostrarAtivo() : this.mostrarInativo()
  }

  get suportado() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  async registro() {
    return navigator.serviceWorker.ready
  }

  async inscricaoAtual() {
    try { return await (await this.registro()).pushManager.getSubscription() } catch (_) { return null }
  }

  async ativar() {
    const permissao = await Notification.requestPermission()
    if (permissao !== "granted") return this.mostrarBloqueado()

    try {
      const inscricao = await (await this.registro()).pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.bytes(this.chaveValue)
      })
      const resposta = await this.enviar("POST", { inscricao: inscricao.toJSON() })
      if (!resposta.ok) throw new Error("recusada")
      this.mostrarAtivo()
    } catch (_) {
      this.mostrar("Não foi possível ativar os avisos neste aparelho. Tente de novo.", { ativar: true, desativar: false })
    }
  }

  async desativar() {
    const inscricao = await this.inscricaoAtual()
    if (inscricao) {
      await this.enviar("DELETE", { endpoint: inscricao.endpoint })
      await inscricao.unsubscribe()
    }
    this.mostrarInativo()
  }

  enviar(metodo, corpo) {
    return fetch(this.urlValue, {
      method: metodo,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
      },
      body: JSON.stringify(corpo)
    })
  }

  mostrarAtivo() {
    this.mostrar("Avisos ativados neste aparelho: você recebe as notificações mesmo com o sistema fechado.", { ativar: false, desativar: true })
  }

  mostrarInativo() {
    this.mostrar("Receba as notificações neste aparelho mesmo com o sistema fechado.", { ativar: true, desativar: false })
  }

  mostrarBloqueado() {
    this.mostrar("Os avisos estão bloqueados neste navegador. Libere as notificações do site nas configurações do navegador.", { ativar: false, desativar: false })
  }

  mostrar(texto, { ativar, desativar }) {
    this.estadoTarget.textContent = texto
    this.ativarTarget.hidden = !ativar
    this.desativarTarget.hidden = !desativar
  }

  // Chave pública VAPID (base64 url-safe) -> Uint8Array
  bytes(base64) {
    const preenchida = (base64 + "=".repeat((4 - (base64.length % 4)) % 4)).replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(preenchida), (caractere) => caractere.charCodeAt(0))
  }
}
