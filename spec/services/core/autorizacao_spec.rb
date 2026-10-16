require "rails_helper"

RSpec.describe Core::Autorizacao do
  subject(:autorizacao) { described_class.new(user) }

  include_context "com catálogo de exemplo"


  let(:user) { create(:user) }

  def conceder(modulo, papel, escopo: nil, status: "ativo")
    create(:core_concessao, user: user, modulo: modulo, papel: papel, status: status,
                            escopo_tipo: escopo&.first, escopo_id: escopo&.last)
  end

  describe "#acesso?" do
    it "abre módulo com papel automático a todo usuário ativo" do
      expect(autorizacao.acesso?(:exemplo)).to be(true)
    end

    it "fecha módulo sem papel automático para quem não tem acesso" do
      expect(autorizacao.acesso?(:fechado)).to be(false)
    end

    it "abre módulo fechado para quem tem acesso ativo" do
      conceder("fechado", "leitor")

      expect(autorizacao.acesso?(:fechado)).to be(true)
    end

    it "bloqueia quem tem o acesso inativado, mesmo com papel automático" do
      create(:core_acesso, user: user, modulo: "exemplo", status: "inativo")

      expect(autorizacao.acesso?(:exemplo)).to be(false)
      expect(autorizacao.papeis(:exemplo)).to be_empty
      expect(autorizacao.pode?("exemplo.minha_ficha.ver")).to be(false)
    end

    it "nega tudo a usuário desativado, ausente ou módulo desconhecido" do
      conceder("fechado", "admin")
      user.update!(status: false)

      expect(autorizacao.acesso?(:fechado)).to be(false)
      expect(described_class.new(nil).acesso?(:exemplo)).to be(false)
      expect(described_class.new(create(:user)).acesso?(:nada)).to be(false)
    end
  end

  describe "#papeis e #pode?" do
    it "dá o papel automático sem concessão" do
      expect(autorizacao.papeis(:exemplo)).to eq([ "usuario" ])
      expect(autorizacao.pode?("exemplo.minha_ficha.ver")).to be(true)
      expect(autorizacao.pode?("exemplo.pessoas.ver")).to be(false)
    end

    it "une as permissões de vários papéis" do
      conceder("exemplo", "operador")

      expect(autorizacao.papeis(:exemplo)).to contain_exactly("operador", "usuario")
      expect(autorizacao).to be_papel(:exemplo, :operador)
      expect(autorizacao.permissoes).to contain_exactly(
        "exemplo.pessoas.ver", "exemplo.pessoas.editar", "exemplo.minha_ficha.ver"
      )
    end

    it "ignora concessão revogada" do
      conceder("exemplo", "operador", status: "inativo")

      expect(autorizacao.pode?("exemplo.pessoas.editar")).to be(false)
    end

    it "levanta erro para permissão fora do catálogo" do
      expect { autorizacao.pode?("exemplo.nao.existe") }.to raise_error(ArgumentError, /fora do catálogo/)
    end
  end

  describe "escopo" do
    before { conceder("exemplo", "operador", escopo: [ "rh_unidade", 7 ]) }

    it "vale no escopo concedido e em consultas sem escopo" do
      expect(autorizacao.pode?("exemplo.pessoas.editar")).to be(true)
      expect(autorizacao.pode?("exemplo.pessoas.editar", escopo: [ "rh_unidade", 7 ])).to be(true)
      expect(autorizacao.pode?("exemplo.pessoas.editar", escopo: { tipo: :rh_unidade, id: "7" })).to be(true)
      expect(autorizacao.escopos("exemplo.pessoas.editar")).to eq([ [ "rh_unidade", 7 ] ])
    end

    it "não vale em outro escopo" do
      expect(autorizacao.pode?("exemplo.pessoas.editar", escopo: [ "rh_unidade", 8 ])).to be(false)
    end

    it "concessão global vale em qualquer escopo" do
      conceder("exemplo", "admin")

      expect(autorizacao.escopos("exemplo.pessoas.editar")).to eq(:todos)
      expect(autorizacao.pode?("exemplo.pessoas.editar", escopo: [ "rh_unidade", 8 ])).to be(true)
    end

    it "permissão de papel automático vale em qualquer escopo" do
      expect(autorizacao.escopos("exemplo.minha_ficha.ver")).to eq(:todos)
    end

    it "aceita um registro como escopo" do
      expect(described_class.normalizar_escopo(user)).to eq([ "user", user.id ])
    end
  end

  describe "#pode!" do
    it "levanta Core::AcessoNegado com a permissão" do
      expect { autorizacao.pode!("fechado.coisas.ver") }
        .to raise_error(Core::AcessoNegado) { |erro| expect(erro.permissao).to eq("fechado.coisas.ver") }
      expect(autorizacao.pode!("exemplo.minha_ficha.ver")).to be(true)
    end
  end

  describe "cache", :com_cache do
    it "guarda as concessões e esquece quando uma concessão muda" do
      expect(described_class.new(user).pode?("fechado.coisas.ver")).to be(false)

      conceder("fechado", "leitor")

      expect(described_class.new(user).pode?("fechado.coisas.ver")).to be(true)
    end

    it "não consulta o banco de novo enquanto nada muda" do
      described_class.new(user).acesso?(:exemplo)

      expect { described_class.new(user).pode?("exemplo.pessoas.ver") }.not_to exceed_query_limit(0)
    end
  end
end
