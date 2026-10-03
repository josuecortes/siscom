Rails.application.routes.draw do
  # Login. A recuperação de senha por e-mail fica desligada (sem servidor de
  # e-mail): a redefinição é feita por um administrador, com senha temporária.
  devise_for :users, controllers: { sessions: "core/sessoes" }, skip: [ :passwords ]

  resource :meu_perfil, path: "minha-area/perfil", only: %i[show update], controller: "core/meu_perfil"
  resources :notificacoes, path: "minha-area/notificacoes", only: :index, controller: "core/notificacoes" do
    patch :abrir, on: :member
    patch :marcar_todas, on: :collection
  end
  resource :inscricao_push, path: "minha-area/avisos-no-aparelho", only: %i[create destroy], controller: "core/inscricoes_push"
  resource :minha_senha, path: "minha-area/senha", only: %i[edit update], controller: "core/minha_senha"

  # Caminhos em português: /novo e /editar.
  scope path_names: { new: "novo", edit: "editar" } do
    draw :core
    draw :rh
  end

  # App instalável (PWA): manifesto e service worker (views em app/views/pwa).
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "up" => "rails/health#show", as: :rails_health_check

  root "inicio#index"
end
