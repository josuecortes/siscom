import { Controller } from "@hotwired/stimulus"

// Lista de itens para marcar (ex.: equipamentos de um envio): filtra pelo texto digitado, conta os marcados
// e marca de uma vez todas as peças de um kit.
//   <div data-controller="selecao">
//     <input data-selecao-target="busca" data-action="input->selecao#filtrar">
//     <span data-selecao-target="contagem"></span>
//     <label data-selecao-target="linha" data-texto="monitor dell pat001" data-grupo="KIT-000001">
//       <input type="checkbox" data-action="change->selecao#contar"> …
//     <button type="button" data-action="selecao#marcarGrupo" data-selecao-grupo-param="KIT-000001">Kit inteiro</button>
export default class extends Controller {
  static targets = ["busca", "linha", "contagem", "vazio"]

  connect() {
    this.contar()
  }

  filtrar() {
    const termos = this.buscaTarget.value.toLowerCase().split(/\s+/).filter(Boolean)
    let visiveis = 0
    this.linhaTargets.forEach((linha) => {
      const mostra = termos.every((termo) => linha.dataset.texto.includes(termo))
      linha.hidden = !mostra
      if (mostra) visiveis += 1
    })
    if (this.hasVazioTarget) this.vazioTarget.hidden = visiveis > 0
  }

  marcarGrupo(evento) {
    const grupo = String(evento.params.grupo) // o Stimulus converte "20251205145840" em número
    const caixas = this.linhaTargets.filter((linha) => linha.dataset.grupo === grupo).map((linha) => linha.querySelector("input[type=checkbox]:not(:disabled)")).filter(Boolean)
    const marcar = caixas.some((caixa) => !caixa.checked)
    caixas.forEach((caixa) => { caixa.checked = marcar })
    this.contar()
  }

  contar() {
    if (!this.hasContagemTarget) return
    const marcados = this.element.querySelectorAll("input[type=checkbox]:checked").length
    this.contagemTarget.textContent = marcados === 1 ? "1 marcado" : `${marcados} marcados`
  }
}
