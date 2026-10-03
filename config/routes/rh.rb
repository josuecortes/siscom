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

  resources :unidades, only: %i[index new create edit update] do
    member do
      patch :ativar
      patch :desativar
    end
  end
end
