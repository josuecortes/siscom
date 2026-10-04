import { Controller } from "@hotwired/stimulus"

// Ícone flutuante das conversas (porta de chat-launcher.tsx). Fica no <body>: o botão abre e fecha
// o painel com a lista; qualquer botão da página pode abrir direto uma conversa:
//   data-action="lancador#abrirConversa" data-lancador-url-param="/minha-area/conversas/5/painel"
export default class extends Controller {
  static targets = ["painel", "quadro", "botao"]
  static values = { lista: String }

  alternar() {
    this.painelTarget.hidden ? this.abrir(this.listaValue) : this.fechar()
  }

  abrirConversa(evento) {
    evento.preventDefault()
    this.abrir(evento.params.url)
  }

  abrir(url) {
    this.painelTarget.hidden = false
    this.botaoTarget.setAttribute("aria-label", "Fechar conversas")
    // Tirar e pôr o src faz o quadro carregar de novo mesmo quando o endereço é o mesmo.
    this.quadroTarget.removeAttribute("src")
    this.quadroTarget.src = url
  }

  fechar() {
    this.painelTarget.hidden = true
    this.botaoTarget.setAttribute("aria-label", "Abrir conversas")
    this.quadroTarget.removeAttribute("src")
    this.quadroTarget.replaceChildren() // sem a conversa na tela, as mensagens novas contam como não lidas
  }
}
