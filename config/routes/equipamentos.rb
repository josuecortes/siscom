# Rotas do módulo Equipamentos.
namespace :equipamentos do
  # Equipamentos: lista com filtros, ver, cadastrar (individual ou kit), editar, mudar situação e kit.
  resources :itens, only: %i[index show new create edit update] do
    collection do
      get :kit # confere um código de kit (JSON)
      get :opcoes, defaults: { format: :json } # equipamentos da unidade para um envio
    end
    member do
      get :situacao
      patch :mudar_situacao
      get :kit, action: :kit_do_item
      patch :entrar_no_kit
      patch :sair_do_kit
    end
  end
  # Envios: movimentação definitiva e empréstimo/cautela (mesmas telas, tipos diferentes).
  resources :movimentacoes, only: %i[index show new create] do
    member do
      get :cancelamento # painel: quais equipamentos ainda não recebidos deixar de enviar
      patch :cancelar
    end
  end
  resources :emprestimos, only: %i[index show new create], controller: "movimentacoes", defaults: { emprestimo: true } do
    member do
      get :cancelamento
      patch :cancelar
    end
  end
  # Minha área: o que tenho para receber, o que está comigo emprestado e as devoluções para eu receber.
  resources :recebimentos, only: %i[index] do
    member do
      patch :receber             # movimentação: dá o recebido (um equipamento, ou todos os pendentes)
      get :termo                 # empréstimo/cautela: o termo, para aceitar
      patch :aceitar
      get :devolucao             # quem está com o equipamento inicia a devolução (ou troca quem recebe)
      patch :devolver
      get :recebimento_da_devolucao
      patch :receber_devolucao
    end
  end
  get "opcoes/unidades", to: "opcoes#unidades", as: :opcoes_de_unidades, defaults: { format: :json }
  get "opcoes/pessoas", to: "opcoes#pessoas", as: :opcoes_de_pessoas, defaults: { format: :json }
  resource :historico, only: :show, controller: "historico"
  resources :permissoes, only: %i[index edit update]
end
