Rails.application.routes.draw do

  resources :problema_tis
  resources :tipo_problema_tis
  resources :requisicao_tis do
    member do 
      get 'finalizar'
      put 'salvar'
    end
  end
  
  namespace :nuinfo do
    resources :requisicao_tis, only: [:index, :show] do
      get 'pegar'
      member do
        get 'concluir'    
        put 'salvar'
      end
    end
  end

  get 'patio/index'
  get 'patio/entrada'
  get 'patio/saida'

  namespace :useget do
    resources :requisicao_transportes, only: [:index, :show] do
      get 'aprovar'
      get 'negar'    
    end
  end

  resources :servico_transportes, only: [:show, :new, :create, :edit, :update]

  resources :destinos
  resources :passageiros
  resources :requisicao_transportes
  resources :veiculos
  resources :motoristas
  get 'home/index'

  get 'perfil/index'
  put 'perfil/update'
  get 'perfil/alterar_senha'
  put 'perfil/salvar_senha'
  
  resources :usuarios do

  end

  resources :departamentos
  resources :funcoes do
    get 'autocomplete', on: :collection
  end
  
  devise_for :users
  devise_scope :user do
    authenticated :user do
      root 'home#index', as: :authenticated_root
    end
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
end
