Rails.application.routes.draw do
  # Login. A recuperação de senha por e-mail fica desligada (sem servidor de
  # e-mail): a redefinição é feita por um administrador, com senha temporária.
  devise_for :users, controllers: { sessions: "core/sessoes" }, skip: [ :passwords ]

  # Consulta de CEP para formulários com endereço.
  get "cep/:cep", to: "core/cep#show", as: :cep, constraints: { cep: /\d{5}-?\d{3}/ }, defaults: { format: :json }

  # Apoio aos campos com mapa: busca de lugar, endereço de um ponto e imagens do mapa.
  scope "mapa", controller: "core/mapa" do
    get "buscar", action: :buscar, as: :mapa_buscar, defaults: { format: :json }
    get "reverso", action: :reverso, as: :mapa_reverso, defaults: { format: :json }
    get "tiles/:z/:x/:y", action: :tile, as: :mapa_tile, constraints: { z: /\d+/, x: /\d+/, y: /\d+/ }
  end

  resource :meu_perfil, path: "minha-area/perfil", only: %i[show update], controller: "core/meu_perfil"
  resources :notificacoes, path: "minha-area/notificacoes", only: :index, controller: "core/notificacoes" do
    patch :abrir, on: :member
    patch :marcar_todas, on: :collection
  end
  resources :conversas, path: "minha-area/conversas", only: :index, controller: "core/conversas" do
    get :lancador, on: :collection # lista dentro do painel flutuante
    member do
      get :painel # a conversa dentro do painel flutuante
      post :lida
    end
    resources :mensagens, only: :create, controller: "core/mensagens"
  end
  resource :inscricao_push, path: "minha-area/avisos-no-aparelho", only: %i[create destroy], controller: "core/inscricoes_push"
  get "sessao/pulso", to: "core/sessao#pulso", as: :pulso_da_sessao, defaults: { format: :json }
  resource :minha_senha, path: "minha-area/senha", only: %i[edit update], controller: "core/minha_senha"

  # Caminhos em português: /novo e /editar.
  scope path_names: { new: "novo", edit: "editar" } do
    draw :core
    draw :rh
    draw :ti
    draw :transporte
    draw :equipamentos
  end

  # App instalável (PWA): manifesto e service worker (views em app/views/pwa).
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "up" => "rails/health#show", as: :rails_health_check

  root "inicio#index"
end
