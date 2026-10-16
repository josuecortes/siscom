import { Controller } from "@hotwired/stimulus"

// Aviso flutuante: entra deslizando, some sozinho depois de `duracao` ms
// (pausa enquanto o mouse está em cima) e pode ser fechado no X.
export default class extends Controller {
  static values = { duracao: { type: Number, default: 5000 } }

  connect() {
    this.element.classList.add("opacity-0", "translate-x-4")
    requestAnimationFrame(() => this.element.classList.remove("opacity-0", "translate-x-4"))
    this.agendar()
    this.pausar = () => clearTimeout(this.temporizador)
    this.retomar = () => this.agendar()
    this.element.addEventListener("mouseenter", this.pausar)
    this.element.addEventListener("mouseleave", this.retomar)
  }

  disconnect() {
    clearTimeout(this.temporizador)
    this.element.removeEventListener("mouseenter", this.pausar)
    this.element.removeEventListener("mouseleave", this.retomar)
  }

  agendar() {
    clearTimeout(this.temporizador)
    if (this.duracaoValue > 0) this.temporizador = setTimeout(() => this.fechar(), this.duracaoValue)
  }

  fechar() {
    clearTimeout(this.temporizador)
    this.element.classList.add("opacity-0", "translate-x-4")
    setTimeout(() => this.element.remove(), 300)
  }
}
