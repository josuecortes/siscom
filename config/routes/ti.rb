# Rotas do módulo TI.
namespace :ti do
  # Chamados do solicitante.
  resources :chamados, only: %i[index show new create]
  get "opcoes/campos/:campo_id", to: "opcoes#index", as: :opcoes_do_campo, defaults: { format: :json }

  # Itens simples do catálogo (mesma tela para os três).
  %i[categorias perfis_abertura grupos_tecnicos].each do |tabela|
    resources tabela, only: %i[index new create edit update], controller: "catalogo", defaults: { tabela: tabela.to_s } do
      member do
        patch :ativar
        patch :desativar
      end
    end
  end

  # Solicitações do catálogo e seus vínculos (quem abre: perfis; quem atende: grupos).
  resources :solicitacoes, only: %i[index new create edit update] do
    member do
      patch :ativar
      patch :desativar
    end
    resources :campos, only: %i[index new create edit update], controller: "campos_da_solicitacao" do
      member do
        patch :ativar
        patch :desativar
      end
    end
    %w[perfis grupos].each do |tipo|
      resource tipo, only: %i[edit update], controller: "vinculos_da_solicitacao", defaults: { tipo: tipo }
    end
  end

  # Membros de um grupo técnico e perfis de abertura de um usuário.
  resources :grupos_tecnicos, only: [] do
    resource :membros, only: %i[edit update], controller: "membros_do_grupo"
    resource :solicitacoes, only: %i[edit update], controller: "solicitacoes_do_item", defaults: { tipo: "grupo" }
  end
  resources :perfis_abertura, only: [] do
    resource :solicitacoes, only: %i[edit update], controller: "solicitacoes_do_item", defaults: { tipo: "perfil" }
  end
  resources :permissoes, only: %i[index edit update] do
    resource :perfis_abertura, only: %i[edit update], controller: "perfis_do_usuario"
  end
end
