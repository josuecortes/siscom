# Rotas do módulo Transporte.
namespace :transporte do
  # Solicitações do solicitante.
  resources :solicitacoes, only: %i[index show new create edit update] do
    member do
      get :cancelamento
      patch :cancelar
      # O solicitante aceita ou recusa o reagendamento proposto pela operação.
      get :reagendamento
      patch :responder_reagendamento
    end
  end
  # Operação: o técnico vê todas, aprova, cancela, reagenda e abre em nome de outra pessoa.
  resources :operacao, only: %i[index show], controller: "operacao" do
    member do
      patch :aprovar
      get :cancelamento
      patch :cancelar
      get :reagendamento
      patch :reagendar
    end
  end
  # Motorista: inicia e finaliza os trechos (pela linha da Operação; não há mais a tela "Meus serviços").
  resources :servicos, only: [] do
    get :veiculos, on: :collection, defaults: { format: :json }
    member do
      get :inicio
      patch :iniciar
      get :fim
      patch :finalizar
    end
  end
  resources :solicitacoes, only: [] do
    resources :observacoes, only: %i[new create]
  end
  resource :solicitacao_para_outro, only: %i[new create], path: "solicitacoes-para-outra-pessoa", controller: "solicitacoes_para_outro" do
    get :pessoas, defaults: { format: :json }
  end

  %i[motoristas veiculos].each do |recurso|
    resources recurso, only: %i[index new create edit update] do
      member do
        patch :ativar
        patch :desativar
      end
    end
  end
  get "opcoes/unidades", to: "opcoes#unidades", as: :opcoes_de_unidades, defaults: { format: :json }
  # Veículos agora: quais estão livres e quais estão em serviço (o lugar do antigo "pátio").
  resource :veiculos_agora, only: :show, path: "veiculos-agora", controller: "veiculos_agora"
  # Painel de acompanhamento (TV): sem login, com a senha da Configuração.
  resource :acompanhamento, only: %i[show create destroy], controller: "acompanhamento"
  resource :relatorios, only: :show
  resources :permissoes, only: %i[index edit update]
  resource :configuracoes, only: %i[show update]
end
