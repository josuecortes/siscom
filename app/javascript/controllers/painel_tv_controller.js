import { Controller } from "@hotwired/stimulus"

// Painel de TV do Transporte: relógio que anda sozinho e contagem para a próxima atualização.
// O quadro também atualiza na hora quando algo muda na operação (Turbo Streams); aí a contagem recomeça.
export default class extends Controller {
  static targets = ["hora", "data", "contagem", "barra"]
  static values = { intervalo: { type: Number, default: 30 } }

  connect() {
    this.recomecar = this.recomecar.bind(this)
    document.addEventListener("turbo:render", this.recomecar)
    this.recomecar()
    this.relogio = setInterval(() => this.passar(), 1000)
  }

  disconnect() {
    clearInterval(this.relogio)
    document.removeEventListener("turbo:render", this.recomecar)
  }

  recomecar() {
    this.faltam = this.intervaloValue
    this.mostrar()
  }

  passar() {
    this.faltam -= 1
    if (this.faltam <= 0) {
      this.faltam = this.intervaloValue
      window.Turbo.visit(window.location.href, { action: "replace" })
    }
    this.mostrar()
  }

  mostrar() {
    const agora = new Date()
    const fuso = { timeZone: "America/Belem" }
    if (this.hasHoraTarget) this.horaTarget.textContent = agora.toLocaleTimeString("pt-BR", { ...fuso, hour: "2-digit", minute: "2-digit", second: "2-digit" })
    if (this.hasDataTarget) this.dataTarget.textContent = agora.toLocaleDateString("pt-BR", { ...fuso, weekday: "long", day: "2-digit", month: "long" })
    if (this.hasContagemTarget) this.contagemTarget.textContent = `${this.faltam} s`
    if (this.hasBarraTarget) this.barraTarget.style.width = `${(this.faltam / this.intervaloValue) * 100}%`
  }
}
