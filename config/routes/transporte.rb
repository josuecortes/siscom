# Rotas do módulo Transporte.
namespace :transporte do
  resources :permissoes, only: %i[index edit update]
  resource :configuracoes, only: %i[show update]
end
