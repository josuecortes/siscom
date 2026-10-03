import { Controller } from "@hotwired/stimulus"

// Painel de formulário dentro do turbo-frame "painel": trava a rolagem da
// página enquanto está aberto, fecha só pelos botões (Cancelar/Fechar/×), e volta o
// miolo ao topo quando o formulário volta com erro.
export default class extends Controller {
  static targets = ["miolo"]
  static values = { voltar: String }

  connect() {
    document.documentElement.classList.add("overflow-hidden")
    if (this.hasMioloTarget) this.mioloTarget.scrollTop = 0
    // O navegador não aplica o atributo autofocus em conteúdo que chega por turbo-frame.
    this.element.querySelector("[autofocus]")?.focus({ preventScroll: true })
  }

  disconnect() {
    document.documentElement.classList.remove("overflow-hidden")
  }

  fechar() {
    const quadro = this.element.closest("turbo-frame")
    // Aberto direto pela URL (sem a listagem por trás): volta para a listagem.
    if (!quadro || quadro.dataset.abertoNaPagina === "true") {
      if (this.voltarValue) window.Turbo.visit(this.voltarValue)
      return
    }
    quadro.removeAttribute("src")
    quadro.innerHTML = ""
  }
}
