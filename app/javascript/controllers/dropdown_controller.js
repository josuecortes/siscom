import { Controller } from "@hotwired/stimulus"

// Menu suspenso simples: abre/fecha no botão, fecha com Esc ou clique fora.
export default class extends Controller {
  static targets = ["botao", "menu"]

  alternar() {
    this.menuTarget.classList.contains("hidden") ? this.abrir() : this.fechar()
  }

  abrir() {
    this.menuTarget.classList.remove("hidden")
    this.botaoTarget.setAttribute("aria-expanded", "true")
  }

  fechar() {
    this.menuTarget.classList.add("hidden")
    this.botaoTarget.setAttribute("aria-expanded", "false")
  }

  fecharFora(event) {
    if (!this.element.contains(event.target)) this.fechar()
  }
}
