require "rails_helper"

RSpec.describe Core::PoliticaBase do
  include_context "com catálogo de exemplo"

  let(:politica_de_teste) do
    Class.new(described_class) do
      def show? = permissao?("exemplo.pessoas.ver")
      def update? = permissao?("exemplo.pessoas.editar", escopo: [ "user", record.id ])

      const_set(:Scope, Class.new(Core::PoliticaBase::Scope) do
        def resolve = limitar("exemplo.pessoas.ver", tipo: "user", coluna: :id)
      end)
    end
  end

  let(:user) { create(:user) }
  let(:outro) { create(:user) }

  def conceder(papel, escopo: nil)
    create(:core_concessao, user: user, modulo: "exemplo", papel: papel, escopo_tipo: escopo&.first, escopo_id: escopo&.last)
  end

  it "nega tudo por padrão" do
    politica = described_class.new(user, outro)

    expect(%i[index? show? create? new? update? edit? destroy?].map { |acao| politica.public_send(acao) }).to all(be(false))
    expect(described_class::Scope.new(user, User).resolve).to be_empty
  end

  it "consulta as permissões do catálogo" do
    expect(politica_de_teste.new(user, outro).show?).to be(false)

    conceder("operador")

    expect(politica_de_teste.new(user, outro).show?).to be(true)
    expect(politica_de_teste.new(user, outro).edit?).to be(true)
  end

  it "respeita o escopo da concessão" do
    conceder("operador", escopo: [ "user", outro.id ])

    expect(politica_de_teste.new(user, outro).update?).to be(true)
    expect(politica_de_teste.new(user, user).update?).to be(false)
  end

  describe "Scope#limitar" do
    it "devolve nada sem a permissão" do
      expect(politica_de_teste::Scope.new(user, User).resolve).to be_empty
    end

    it "devolve só os registros do escopo concedido" do
      conceder("operador", escopo: [ "user", outro.id ])
      conceder("operador", escopo: [ "rh_unidade", user.id ])

      expect(politica_de_teste::Scope.new(user, User).resolve).to contain_exactly(outro)
    end

    it "devolve tudo com concessão global" do
      conceder("admin")

      expect(politica_de_teste::Scope.new(user, User).resolve).to contain_exactly(user, outro)
    end
  end
end
