# Itens do menu lateral. Na Fase 1 passa a ser montado a partir dos catálogos
# dos módulos (config/modulos/*.yml) e das permissões efetivas do usuário.
module MenuLateralHelper
  def menu_lateral_itens
    [
      { rotulo: "Início", icone: :home, caminho: root_path, exato: true }
    ]
  end

  def item_menu_ativo?(item)
    return request.path == item[:caminho] if item[:exato]

    request.path == item[:caminho] || request.path.start_with?("#{item[:caminho]}/")
  end
end
