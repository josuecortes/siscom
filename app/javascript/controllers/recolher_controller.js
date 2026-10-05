import { Controller } from "@hotwired/stimulus"

// Recolhe e expande um bloco em tela pequena (ex.: os filtros de uma lista no celular). O bloco começa
// recolhido só abaixo do ponto de quebra: as classes do Tailwind ("hidden md:grid") cuidam das telas grandes.
export default class extends Controller {
  static targets = ["bloco", "botao"]

  alternar() {
    const recolhido = this.blocoTarget.classList.toggle("hidden")
    this.botaoTarget.setAttribute("aria-expanded", String(!recolhido))
  }
}
