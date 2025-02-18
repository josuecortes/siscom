Rails.application.routes.draw do

  resources :tarefas do
    collection do
      get :atualizar_status
    end
  end

  resources :acoes do
    resources :etapas
    get 'relatorio', on: :member, defaults: { format: :pdf }
    get 'relatorio_geral', on: :collection, defaults: { format: :pdf }
    get 'relatorio_geral_simplificado', on: :collection, defaults: { format: :pdf }
  end
  
  namespace :transporte_escolar do
    resources :servicos do
      collection do
        post :search
      end
    end
  end
  namespace :transporte_escolar do
    resources :contratos
  end
  namespace :transporte_escolar do
    resources :veiculos
  end
  namespace :transporte_escolar do
    resources :condutores
  end
  namespace :transporte_escolar do
    resources :transportadores
  end
  namespace :transporte_escolar do
    resources :escolas
  end
  namespace :transporte_escolar do
    resources :municipios
  end
  resources :incidentes do
    member do
      get 'finalizar'
      put 'salvar'
    end
  end

  resources :mensagens do
    get 'mensagens_diretas', on: :collection
    get 'refresh', on: :collection
    post 'js_create', on: :collection
    member do
      get 'new_image'
      put 'update_image'
    end
    get 'imagem', on: :collection
  end

  resources :cargos
  resources :tipo_unidades
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
      collection do
        get 'acompanhamento'
        get 'refresh_acompanhamento'
        get 'em_atendimento'
        get 'estatisticas'
        post 'buscar_estatisticas'
      end
      member do
        get 'concluir'
        get 'trocar_tecnico'
        put 'salvar'
        put 'salvar_troca_tecnico'
      end
    end
  end

  get 'patio/index'
  get 'patio/entrada'
  get 'patio/saida'

  namespace :useget do
    resources :requisicao_transportes, only: [:index, :show] do
      get 'aprovar'
      collection do
        get 'acompanhamento'
        get 'refresh_acompanhamento'
      end
      member do
        get 'negar'
        put 'salvar_negacao'
      end
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
    member do
      get 'resetar_senha'
      get 'tornar_requisitante_transporte'
      get 'tornar_tecnico_transporte'
    end
  end

  resources :unidades
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
