import { Controller } from "@hotwired/stimulus"

// Recarrega o turbo-frame em volta com o valor escolhido num campo (ex.: ao escolher
// a entidade de uma fonte, o formulário volta com os campos daquela entidade).
//   <select data-controller="recarregar-quadro" data-recarregar-quadro-url-value="/x/novo"
//           data-recarregar-quadro-parametro-value="entidade" data-action="change->recarregar-quadro#recarregar">
// Com `quadro` (id), recarrega aquele turbo-frame em vez do que está em volta; o valor vem do campo que mudou.
export default class extends Controller {
  static values = { url: String, parametro: String, quadro: String }

  recarregar(evento) {
    const quadro = this.quadroValue ? document.getElementById(this.quadroValue) : this.element.closest("turbo-frame")
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set(this.parametroValue, evento?.target?.value ?? this.element.value)
    if (quadro) quadro.src = url.toString()
  }
}
