import { Controller } from "@hotwired/stimulus"

// Recarrega o turbo-frame em volta com o valor escolhido num campo (ex.: ao escolher
// a entidade de uma fonte, o formulário volta com os campos daquela entidade).
//   <select data-controller="recarregar-quadro" data-recarregar-quadro-url-value="/x/novo"
//           data-recarregar-quadro-parametro-value="entidade" data-action="change->recarregar-quadro#recarregar">
// Com `quadro` (id), recarrega aquele turbo-frame em vez do que está em volta; o valor vem do campo que mudou.
// Com `incluir` (seletor CSS), leva junto o valor de outros campos (parâmetro = data-parametro do campo, ou o name);
// caixa desmarcada não vai, e nome terminado em [] leva todos os valores.
export default class extends Controller {
  static values = { url: String, parametro: String, quadro: String, incluir: String }

  recarregar(evento) {
    const quadro = this.quadroValue ? document.getElementById(this.quadroValue) : this.element.closest("turbo-frame")
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set(this.parametroValue, evento?.target?.value ?? this.element.value)
    if (this.incluirValue) {
      document.querySelectorAll(this.incluirValue).forEach((campo) => {
        const parametro = campo.dataset.parametro || campo.name
        if (!parametro || !campo.value || url.searchParams.has(parametro) && parametro === this.parametroValue) return
        if ([ "checkbox", "radio" ].includes(campo.type) && !campo.checked) return
        // Nome terminado em [] é lista (ex.: caixas marcadas): leva todos os valores.
        if (parametro.endsWith("[]")) url.searchParams.append(parametro, campo.value)
        else url.searchParams.set(parametro, campo.value)
      })
    }
    if (quadro) quadro.src = url.toString()
  }
}
