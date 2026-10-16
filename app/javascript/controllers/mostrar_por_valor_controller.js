import { Controller } from "@hotwired/stimulus"

// Mostra só os blocos que valem para o valor escolhido num campo (ex.: o tipo de um campo de
// formulário decide se aparecem "Opções", "Fonte de dados" ou "Máscara").
//   <div data-controller="mostrar-por-valor">
//     <select data-mostrar-por-valor-target="campo" data-action="change->mostrar-por-valor#atualizar">
//     <div data-mostrar-por-valor-target="bloco" data-valores="selecao selecao_unica">...</div>
export default class extends Controller {
  static targets = ["campo", "bloco"]

  connect() {
    this.atualizar()
  }

  atualizar() {
    const valor = this.campoTarget.value
    this.blocoTargets.forEach((bloco) => {
      const visivel = bloco.dataset.valores.split(" ").includes(valor)
      bloco.hidden = !visivel
      // Campo escondido não é enviado nem validado pelo navegador.
      bloco.querySelectorAll("input, select, textarea").forEach((campo) => { campo.disabled = !visivel })
    })
  }
}
