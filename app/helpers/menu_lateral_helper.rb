# Menu lateral montado a partir dos catálogos dos módulos (config/modulos/*.yml)
# e das permissões efetivas do usuário: "Início" + um grupo por módulo em que o
# usuário entra e enxerga pelo menos um item.
module MenuLateralHelper
  def menu_lateral_itens
    inicio = { rotulo: "Início", icone: :home, caminho: root_path, exato: true }

    [ inicio ] + Core::Catalogo.modulos.filter_map { |modulo| grupo_do_menu(modulo) }
  end

  def item_menu_ativo?(item)
    return item[:filhos].any? { |filho| item_menu_ativo?(filho) } if item[:filhos]
    return request.path == item[:caminho] if item[:exato]

    request.path == item[:caminho] || request.path.start_with?("#{item[:caminho]}/")
  end

  private

  def grupo_do_menu(modulo)
    return unless autorizacao.acesso?(modulo.chave)

    filhos = modulo.menu.filter_map do |item|
      next if item.permissao && !pode?("#{modulo.chave}.#{item.permissao}")

      { rotulo: item.rotulo, icone: (item.icone || modulo.icone || "list-rich").to_sym, caminho: public_send(item.rota) }
    end
    return if filhos.empty?

    { rotulo: modulo.nome, icone: (modulo.icone || "list-rich").to_sym, filhos: filhos }
  end
end
