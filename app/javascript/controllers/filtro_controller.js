import { Controller } from "@hotwired/stimulus"

// Filtros de listagem: aplica sozinho ao digitar (com uma pequena espera) ou
// ao trocar um select, como pede o padrão do seed.
export default class extends Controller {
  static values = { espera: { type: Number, default: 350 } }

  digitar() {
    clearTimeout(this.temporizador)
    this.temporizador = setTimeout(() => this.element.requestSubmit(), this.esperaValue)
  }

  aplicar() {
    clearTimeout(this.temporizador)
    this.element.requestSubmit()
  }

  disconnect() {
    clearTimeout(this.temporizador)
  }
}
