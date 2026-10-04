# Menu lateral montado a partir dos catálogos dos módulos (config/modulos/*.yml)
# e das permissões efetivas do usuário: "Início", "Minha área" (como no seed: o dia a dia
# de qualquer usuário — itens marcados com `minha_area: true` nos catálogos, mais Notificações)
# e um grupo por módulo em que o usuário entra e enxerga pelo menos um item.
module MenuLateralHelper
  def menu_lateral_itens
    inicio = { rotulo: "Início", icone: :home, caminho: root_path, exato: true }

    [ inicio, minha_area ] + Core::Catalogo.modulos.filter_map { |modulo| grupo_do_menu(modulo) }
  end

  def item_menu_ativo?(item)
    return item[:filhos].any? { |filho| item_menu_ativo?(filho) } if item[:filhos]
    return request.path == item[:caminho] if item[:exato]

    request.path == item[:caminho] || request.path.start_with?("#{item[:caminho]}/")
  end

  private

  def minha_area
    filhos = Core::Catalogo.modulos.flat_map do |modulo|
      next [] unless autorizacao.acesso?(modulo.chave)

      itens_visiveis(modulo).select(&:minha_area).map { |item| folha_do_menu(modulo, item) }
    end

    { rotulo: "Minha área", icone: :user, filhos: filhos + [ { rotulo: "Notificações", icone: :bell, caminho: notificacoes_path } ] }
  end

  def itens_visiveis(modulo) = modulo.menu.reject { |item| item.permissao && !pode?("#{modulo.chave}.#{item.permissao}") }

  def grupo_do_menu(modulo)
    return unless autorizacao.acesso?(modulo.chave)

    visiveis = itens_visiveis(modulo).reject(&:minha_area)
    return if visiveis.empty?

    # Itens com `grupo:` no catálogo viram um subgrupo (ex.: "Referências"), na posição do primeiro deles.
    filhos = visiveis.chunk_while { |anterior, atual| anterior.grupo.present? && anterior.grupo == atual.grupo }.map do |itens|
      folhas = itens.map { |item| folha_do_menu(modulo, item) }
      itens.first.grupo.present? ? { rotulo: itens.first.grupo, icone: :list_rich, filhos: folhas } : folhas.first
    end

    { rotulo: modulo.nome, icone: (modulo.icone || "list-rich").to_sym, filhos: filhos }
  end

  def folha_do_menu(modulo, item)
    { rotulo: item.rotulo, icone: (item.icone || modulo.icone || "list-rich").to_sym, caminho: public_send(item.rota) }
  end
end
