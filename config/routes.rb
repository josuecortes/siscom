Rails.application.routes.draw do

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
