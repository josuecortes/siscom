# Rotas do módulo TI.
namespace :ti do
  resources :permissoes, only: %i[index edit update]
end
