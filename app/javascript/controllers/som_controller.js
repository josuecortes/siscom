import { Controller } from "@hotwired/stimulus"
import { tocarUmaVez } from "sons"

// Pedido de alerta sonoro que chega pelo tempo real (Turbo Streams) junto com uma notificação ou mensagem nova:
//   <span data-controller="som" data-som-tipo-value="notificacao" data-som-numero-value="123"></span>
// Toca uma vez por número em todo o navegador (ver sons.js) e some.
export default class extends Controller {
  static values = { tipo: String, numero: Number }

  connect() {
    tocarUmaVez(this.tipoValue, this.numeroValue)
    this.element.remove()
  }
}
