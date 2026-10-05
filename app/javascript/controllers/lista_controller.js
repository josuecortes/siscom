import { Controller } from "@hotwired/stimulus"

// Lista de itens repetidos num formulário (passageiros, destinos): "Adicionar" copia o modelo
// (<template>) trocando NOVO por um índice único; "Remover" tira o item (sempre fica pelo menos um).
//   <div data-controller="lista">
//     <div data-lista-target="itens"> <div data-lista-target="item">…</div> </div>
//     <template data-lista-target="modelo"> <div data-lista-target="item">… name="x[NOVO][nome]" …</div> </template>
//     <button type="button" data-action="lista#adicionar">Adicionar</button>
export default class extends Controller {
  static targets = ["itens", "item", "modelo"]

  adicionar() {
    const indice = `${Date.now()}${Math.floor(Math.random() * 1000)}`
    this.itensTarget.insertAdjacentHTML("beforeend", this.modeloTarget.innerHTML.replaceAll("NOVO", indice))
    this.itemTargets.at(-1)?.querySelector("input, select, textarea")?.focus()
  }

  remover(evento) {
    if (this.itemTargets.length <= 1) return
    evento.target.closest("[data-lista-target='item']")?.remove()
  }
}
