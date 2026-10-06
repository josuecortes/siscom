// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "confirmacao"
import "pwa"

// Um painel aberto não é fechado pelo refresh da página por baixo (outra pessoa mexeu na lista).
// O mesmo vale para o campo de data com calendário (o embrulho é criado no navegador pelo controller `mascara`):
// se o refresh o desmontasse, a pessoa perderia o que estava digitando.
document.addEventListener("turbo:before-morph-element", (evento) => {
  if (evento.target.id === "painel" && evento.target.childElementCount > 0) evento.preventDefault()
  if (evento.target.dataset?.calendario) evento.preventDefault()
})
