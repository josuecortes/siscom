# Rotas do módulo TI.
namespace :ti do
  # Chamados do solicitante.
  resources :chamados, only: %i[index show new create edit update] do
    member do
      get :resposta
      patch :responder
      get :finalizacao
      patch :finalizar
      get :cancelamento
      patch :cancelar
    end
  end
  # Operação: os chamados que triadores, técnicos e supervisão pegam e atendem.
  resources :operacao, only: %i[index show], controller: "operacao" do
    member do
      get :etapa # escolhe a mudança de etapa (as ações ficam na linha da lista)
      get "acoes/:acao", action: :acao, as: :acao
      post "acoes/:acao", action: :executar
    end
  end
  # Painel de acompanhamento (TV): sem login, com a senha da Configuração.
  resource :acompanhamento, only: %i[show create destroy], controller: "acompanhamento"
  resource :configuracoes, only: %i[show update]
  # A TI abre o chamado em nome de outra pessoa (que passa a ser a dona).
  resource :chamado_para_outro, only: %i[new create], path: "chamados-para-outra-pessoa", controller: "chamados_para_outro"
  get "opcoes/usuarios", to: "opcoes#usuarios", as: :opcoes_de_usuarios, defaults: { format: :json }
  get "opcoes/operadores", to: "opcoes#operadores", as: :opcoes_de_operadores, defaults: { format: :json }
  get "opcoes/usuarios-do-perfil", to: "opcoes#usuarios_do_perfil", as: :opcoes_de_usuarios_do_perfil, defaults: { format: :json }
  get "opcoes/solicitacoes", to: "opcoes#solicitacoes", as: :opcoes_de_solicitacoes, defaults: { format: :json }
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
    resource :membros, only: %i[edit create destroy], controller: "membros_do_grupo"
    resource :solicitacoes, only: %i[edit create destroy], controller: "solicitacoes_do_item", defaults: { tipo: "grupo" }
  end
  resources :perfis_abertura, only: [] do
    resource :solicitacoes, only: %i[edit create destroy], controller: "solicitacoes_do_item", defaults: { tipo: "perfil" }
    resource :usuarios, only: %i[edit create destroy], controller: "usuarios_do_perfil"
  end
  resources :permissoes, only: %i[index edit update] do
    resource :perfis_abertura, only: %i[edit update], controller: "perfis_do_usuario"
  end
end
