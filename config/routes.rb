Rails.application.routes.draw do
  # Login. A recuperação de senha por e-mail fica desligada (sem servidor de
  # e-mail): a redefinição é feita por um administrador, com senha temporária.
  devise_for :users, controllers: { sessions: "core/sessoes" }, skip: [ :passwords ]

  resource :meu_perfil, path: "minha-area/perfil", only: %i[show update], controller: "core/meu_perfil"
  resource :minha_senha, path: "minha-area/senha", only: %i[edit update], controller: "core/minha_senha"

  # Caminhos em português: /novo e /editar.
  scope path_names: { new: "novo", edit: "editar" } do
    draw :core
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "inicio#index"
end
