// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "confirmacao"
import "pwa"
import "sons"
import "arquivos"
import "sessao"

// Um painel aberto não é fechado pelo refresh da página por baixo (outra pessoa mexeu na lista).
// O mesmo vale para o campo de data com calendário (o embrulho é criado no navegador pelo controller `mascara`):
// se o refresh o desmontasse, a pessoa perderia o que estava digitando.
// Menu suspenso aberto (sino, conta) continua aberto quando a página se atualiza sozinha por baixo
// (ex.: uma notificação nova atualiza o Início no instante em que a pessoa abre o sino).
document.addEventListener("turbo:before-morph-attribute", (evento) => {
  const elemento = evento.target
  const aberto = elemento.dataset?.dropdownTarget === "menu" && !elemento.classList.contains("hidden")
  const botaoAberto = elemento.dataset?.dropdownTarget === "botao" && elemento.getAttribute("aria-expanded") === "true"
  if ((aberto && evento.detail.attributeName === "class") || (botaoAberto && evento.detail.attributeName === "aria-expanded")) evento.preventDefault()
})

document.addEventListener("turbo:before-morph-element", (evento) => {
  if (evento.target.id === "painel" && evento.target.childElementCount > 0) evento.preventDefault()
  if (evento.target.dataset?.calendario) evento.preventDefault()
})
