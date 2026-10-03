import { Controller } from "@hotwired/stimulus"

// Menu lateral: recolher no desktop (persistido) e gaveta no celular.
export default class extends Controller {
  static targets = ["gaveta"]

  alternarRecolhido() {
    const raiz = document.documentElement
    const recolhido = raiz.dataset.menu !== "recolhido"
    if (recolhido) {
      raiz.dataset.menu = "recolhido"
    } else {
      delete raiz.dataset.menu
    }
    try { localStorage.setItem("siscom-menu", recolhido ? "recolhido" : "aberto") } catch (_) {}
  }

  abrirGaveta() {
    this.gavetaTarget.classList.remove("hidden")
  }

  fecharGaveta() {
    this.gavetaTarget.classList.add("hidden")
  }
}
