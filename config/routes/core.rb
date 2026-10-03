# Rotas do módulo Core (administração).
namespace :core do
  resources :usuarios, only: %i[index new create edit update] do
    member do
      patch :ativar
      patch :desativar
      patch :redefinir_senha
    end
  end
end
