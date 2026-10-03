Rails.application.routes.draw do
  # Login. A recuperação de senha por e-mail fica desligada (sem servidor de
  # e-mail): a redefinição é feita por um administrador, com senha temporária.
  devise_for :users, controllers: { sessions: "core/sessoes" }, skip: [ :passwords ]

  resource :minha_senha, path: "minha-area/senha", only: %i[edit update], controller: "core/minha_senha"

  get "up" => "rails/health#show", as: :rails_health_check

  root "inicio#index"
end
