# Rotas do módulo Core (administração).
namespace :core do
  resources :usuarios, only: %i[index new create edit update] do
    member do
      patch :ativar
      patch :desativar
      patch :redefinir_senha
    end

    # Editor de acessos por módulo: papéis (conceder/revogar) e bloqueio do módulo.
    resource :acessos, only: %i[show create update destroy], controller: "acessos"
  end
end
