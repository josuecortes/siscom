import { Controller } from "@hotwired/stimulus"

// Menu lateral: recolher no desktop (persistido) e gaveta no celular.
export default class extends Controller {
  static targets = ["gaveta", "botaoRecolher", "rolagem"]

  connect() {
    this.atualizarBotao()
    this.mostrarItemAtivo()
  }

  alternarRecolhido() {
    const raiz = document.documentElement
    const recolhido = raiz.dataset.menu !== "recolhido"
    if (recolhido) {
      raiz.dataset.menu = "recolhido"
    } else {
      delete raiz.dataset.menu
    }
    try { localStorage.setItem("siscom-menu", recolhido ? "recolhido" : "aberto") } catch (_) {}
    this.atualizarBotao()
  }

  abrirGaveta() {
    this.gavetaTarget.classList.remove("hidden")
    this.mostrarItemAtivo()
  }

  fecharGaveta() {
    this.gavetaTarget.classList.add("hidden")
  }

  // O botão do topo diz o que o clique vai fazer (como no seed).
  atualizarBotao() {
    if (!this.hasBotaoRecolherTarget) return
    const recolhido = document.documentElement.dataset.menu === "recolhido"
    this.botaoRecolherTarget.setAttribute("aria-label", recolhido ? "Expandir menu lateral" : "Recolher menu lateral")
    this.botaoRecolherTarget.setAttribute("aria-expanded", recolhido ? "false" : "true")
  }

  // Em menus longos, rola a lista até o item da página atual.
  mostrarItemAtivo() {
    this.rolagemTargets.forEach((lista) => {
      const ativo = lista.querySelector('[aria-current="page"]')
      if (ativo) ativo.scrollIntoView({ block: "nearest", inline: "nearest" })
    })
  }
}
