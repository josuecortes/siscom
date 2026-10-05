# Rotas do módulo Transporte.
namespace :transporte do
  # Solicitações do solicitante.
  resources :solicitacoes, only: %i[index show new create]

  %i[motoristas veiculos].each do |recurso|
    resources recurso, only: %i[index new create edit update] do
      member do
        patch :ativar
        patch :desativar
      end
    end
  end
  resources :permissoes, only: %i[index edit update]
  resource :configuracoes, only: %i[show update]
end
