require "rails_helper"

RSpec.describe MenuLateralHelper do
  include_context "com catálogo de exemplo"

  let(:user) { create(:user) }
  let(:autorizacao) { Core::Autorizacao.new(user) }

  # No app, `autorizacao` e `pode?` vêm do controller (Core::ControleDeAcesso).
  before do
    regras = autorizacao
    helper.define_singleton_method(:autorizacao) { regras }
    helper.define_singleton_method(:pode?) { |permissao| regras.pode?(permissao) }
  end

  it "mostra só o Início para quem não enxerga nenhum item dos módulos" do
    expect(helper.menu_lateral_itens.pluck(:rotulo)).to eq([ "Início" ])
  end

  it "mostra o grupo do módulo com os itens permitidos" do
    create(:core_concessao, user: user, modulo: "exemplo", papel: "operador")

    grupo = helper.menu_lateral_itens.last

    expect(grupo).to include(rotulo: "Exemplo", icone: :people)
    expect(grupo[:filhos]).to eq([ { rotulo: "Pessoas", icone: :people, caminho: "/" } ])
  end

  it "esconde o módulo de quem teve o acesso inativado" do
    create(:core_concessao, user: user, modulo: "exemplo", papel: "operador")
    Core::Acesso.find_by!(user: user, modulo: "exemplo").inativo!

    expect(helper.menu_lateral_itens.pluck(:rotulo)).to eq([ "Início" ])
  end

  describe "#item_menu_ativo?" do
    before { allow(helper.request).to receive(:path).and_return("/rh/pessoas/3") }

    it "marca o item pelo prefixo do caminho, ou exato quando pedido" do
      expect(helper.item_menu_ativo?(caminho: "/rh/pessoas")).to be(true)
      expect(helper.item_menu_ativo?(caminho: "/rh/pessoas", exato: true)).to be(false)
      expect(helper.item_menu_ativo?(caminho: "/rh/pes")).to be(false)
    end

    it "marca o grupo quando um filho está ativo" do
      expect(helper.item_menu_ativo?(filhos: [ { caminho: "/ti" }, { caminho: "/rh/pessoas" } ])).to be(true)
      expect(helper.item_menu_ativo?(filhos: [ { caminho: "/ti" } ])).to be(false)
    end
  end
end
