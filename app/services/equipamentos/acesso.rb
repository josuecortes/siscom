module Equipamentos
  # Quem enxerga e mexe em quê. O administrador vê e age em todas as unidades. O gestor vê, cadastra, movimenta
  # e empresta só os equipamentos das unidades em que está lotado (lotações ativas do RH); o que está emprestado
  # para a unidade dele, ele vê, mas não mexe (quem recebe emprestado só devolve).
  module Acesso
    VER = "equipamentos.itens.ver".freeze
    TODAS = "equipamentos.itens.ver_todas_unidades".freeze
    GERENCIAR = "equipamentos.itens.gerenciar".freeze
    MOVIMENTAR = "equipamentos.movimentacoes.criar".freeze
    EMPRESTAR = "equipamentos.emprestimos.criar".freeze
    ADMINISTRAR = "equipamentos.recebimentos.administrar".freeze

    module_function

    def pode?(user, permissao) = Core::Autorizacao.new(user).pode?(permissao)
    def todas?(user) = pode?(user, TODAS)

    # Unidades do RH em que a pessoa está lotada: [Rh::Api::Unidade].
    def unidades_de(user) = Rh::Api.lotacoes_ativas(user).map(&:unidade).uniq(&:id)
    def ids_das_unidades_de(user) = unidades_de(user).map(&:id)

    def itens_visiveis(user)
      return Equipamentos::Item.none unless pode?(user, VER)

      todas?(user) ? Equipamentos::Item.all : Equipamentos::Item.das_unidades(ids_das_unidades_de(user))
    end

    def envios_visiveis(user)
      return Equipamentos::Movimentacao.none unless pode?(user, VER)

      todas?(user) ? Equipamentos::Movimentacao.all : Equipamentos::Movimentacao.das_unidades(ids_das_unidades_de(user))
    end

    # Age sobre os equipamentos da unidade (dona): é administrador ou está lotado nela.
    def age_na_unidade?(user, rh_unidade_id) = todas?(user) || ids_das_unidades_de(user).include?(rh_unidade_id)

    def pode_gerenciar?(user, item) = pode?(user, GERENCIAR) && age_na_unidade?(user, item.rh_unidade_id)
  end
end
