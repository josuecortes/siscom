Rails.application.routes.draw do

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
