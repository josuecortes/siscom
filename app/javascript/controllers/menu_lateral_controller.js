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

  // Menu recolhido: o painel flutuante do grupo aparece por CSS (hover/foco);
  // aqui só o empurramos para caber na altura da tela.
  ajustarFlutuante(event) {
    const painel = event.currentTarget.querySelector("[data-flutuante]")
    if (!painel) return
    painel.style.marginTop = "0px"
    const { top, bottom, height } = painel.getBoundingClientRect()
    if (height === 0) return
    const margem = 8
    let ajuste = 0
    if (bottom > window.innerHeight - margem) ajuste = window.innerHeight - margem - bottom
    if (top + ajuste < margem) ajuste = margem - top
    painel.style.marginTop = `${ajuste}px`
  }

  // Em menus longos, rola a lista até o item da página atual.
  mostrarItemAtivo() {
    this.rolagemTargets.forEach((lista) => {
      const ativo = lista.querySelector('[aria-current="page"]')
      if (ativo) ativo.scrollIntoView({ block: "nearest", inline: "nearest" })
    })
  }
}
