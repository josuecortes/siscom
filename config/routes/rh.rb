# Rotas do módulo RH.
namespace :rh do
  # Tabelas de referência (mesma tela para as cinco).
  %i[tipos_vinculo cargos funcoes tipos_unidade tipos_local].each do |tabela|
    resources tabela, only: %i[index new create edit update], controller: "tabelas", defaults: { tabela: tabela.to_s } do
      member do
        patch :ativar
        patch :desativar
      end
    end
  end

  get "opcoes/:fonte", to: "opcoes#index", as: :opcoes, defaults: { format: :json }

  resource :minha_ficha, only: :show, controller: "minha_ficha"

  resources :pessoas, only: %i[index show new create edit update] do
    resources :lotacoes, only: %i[new create], controller: "lotacoes_da_pessoa"
  end
  resources :lotacoes, only: %i[index new create] do
    patch :encerrar, on: :member
  end

  resources :acessos, only: %i[index edit update]
  resources :pendencias, only: :index do
    patch :resolver, on: :member
  end

  resources :unidades, only: %i[index new create edit update] do
    member do
      patch :ativar
      patch :desativar
    end
  end
end
