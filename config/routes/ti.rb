# Rotas do módulo TI.
namespace :ti do
  # Itens simples do catálogo (mesma tela para os três).
  %i[categorias perfis_abertura grupos_tecnicos].each do |tabela|
    resources tabela, only: %i[index new create edit update], controller: "catalogo", defaults: { tabela: tabela.to_s } do
      member do
        patch :ativar
        patch :desativar
      end
    end
  end

  # Membros de um grupo técnico e perfis de abertura de um usuário.
  resources :grupos_tecnicos, only: [] do
    resource :membros, only: %i[edit update], controller: "membros_do_grupo"
  end
  resources :permissoes, only: %i[index edit update] do
    resource :perfis_abertura, only: %i[edit update], controller: "perfis_do_usuario"
  end
end
