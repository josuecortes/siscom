// Troca o window.confirm do Turbo (data-turbo-confirm) pelo diálogo do sistema
// (app/views/compartilhado/_confirmacao.html.erb). Título, rótulo do botão e tom
// vêm de data-confirmacao-titulo / -rotulo / -tom no formulário ou no botão.
import { Turbo } from "@hotwired/turbo-rails"

function dado(nome, formulario, botao) {
  return botao?.dataset[nome] || formulario?.dataset[nome] || ""
}

Turbo.config.forms.confirm = (mensagem, formulario, botao) => {
  const dialogo = document.getElementById("confirmacao")
  if (!dialogo) return Promise.resolve(window.confirm(mensagem))

  const confirmar = dialogo.querySelector("[data-confirmacao='confirmar']")
  const rotulo = dado("confirmacaoRotulo", formulario, botao) || "Confirmar"
  dialogo.querySelector("#confirmacao_titulo").textContent = dado("confirmacaoTitulo", formulario, botao) || rotulo
  dialogo.querySelector("#confirmacao_descricao").textContent = mensagem
  confirmar.textContent = rotulo
  confirmar.dataset.tom = dado("confirmacaoTom", formulario, botao) || "perigo"

  return new Promise((resolve) => {
    const anterior = document.activeElement
    const encerrar = (resposta) => {
      dialogo.hidden = true
      dialogo.removeEventListener("click", aoClicar)
      window.removeEventListener("keydown", aoTeclar)
      anterior?.focus?.()
      resolve(resposta)
    }
    const aoClicar = (evento) => {
      const acao = evento.target.closest("[data-confirmacao]")?.dataset.confirmacao
      if (acao === "confirmar") encerrar(true)
      if (acao === "cancelar") encerrar(false)
    }
    const aoTeclar = (evento) => { if (evento.key === "Escape") encerrar(false) }

    dialogo.addEventListener("click", aoClicar)
    window.addEventListener("keydown", aoTeclar)
    dialogo.hidden = false
    confirmar.focus()
  })
}
