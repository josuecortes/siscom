import { Controller } from "@hotwired/stimulus"

// Mostra/oculta o conteúdo de um campo de senha.
export default class extends Controller {
  static targets = ["campo", "botao", "risco"]

  alternar() {
    const visivel = this.campoTarget.type === "password"
    this.campoTarget.type = visivel ? "text" : "password"
    this.riscoTarget.classList.toggle("hidden", !visivel)
    const rotulo = visivel ? "Ocultar senha" : "Visualizar senha"
    this.botaoTarget.setAttribute("aria-label", rotulo)
    this.botaoTarget.title = rotulo
  }
}
