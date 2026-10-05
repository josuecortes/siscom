// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "confirmacao"
import "pwa"

// Um painel aberto não é fechado pelo refresh da página por baixo (outra pessoa mexeu na lista).
document.addEventListener("turbo:before-morph-element", (evento) => {
  if (evento.target.id === "painel" && evento.target.childElementCount > 0) evento.preventDefault()
})
