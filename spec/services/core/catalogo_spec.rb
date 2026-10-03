require "rails_helper"

RSpec.describe Core::Catalogo do
  subject(:catalogo) { described_class.new(Rails.root.join("spec/fixtures/modulos")) }

  let(:modulo) { catalogo.modulo(:exemplo) }

  def catalogo_com(yaml)
    Dir.mktmpdir do |pasta|
      File.write(File.join(pasta, "ruim.yml"), yaml)
      described_class.new(pasta)
    end
  end

  it "carrega o módulo pelo nome do arquivo" do
    expect(catalogo.modulos.map(&:chave)).to eq([ "exemplo" ])
    expect(modulo.nome).to eq("Exemplo")
    expect(modulo.icone).to eq("people")
    expect(catalogo).to be_modulo("exemplo")
  end

  it "expande * para todas as permissões do módulo" do
    expect(modulo.permissoes_do_papel(:admin)).to eq(Set["pessoas.ver", "pessoas.editar", "minha_ficha.ver"])
    expect(modulo.permissoes_do_papel(:operador)).to eq(Set["pessoas.ver", "pessoas.editar"])
    expect(modulo.permissoes_do_papel(:inexistente)).to be_empty
  end

  it "conhece papéis automáticos e regras de concessão" do
    expect(modulo.papeis_automaticos.map(&:chave)).to eq([ "usuario" ])
    expect(modulo.papeis_concediveis_por(:admin)).to eq(%w[admin operador])
    expect(modulo.papeis_concediveis_por(:operador)).to eq([])
    expect(modulo).to be_papel(:operador)
  end

  it "responde por permissões com a chave completa" do
    expect(catalogo.permissao?("exemplo.pessoas.editar")).to be(true)
    expect(catalogo.permissao?("exemplo.nao.existe")).to be(false)
    expect(catalogo.permissao?("outro.pessoas.editar")).to be(false)
    expect(catalogo.separar("exemplo.pessoas.editar")).to eq([ "exemplo", "pessoas.editar" ])
  end

  it "monta os itens de menu" do
    item = modulo.menu.first

    expect(item.to_h).to eq(rotulo: "Pessoas", rota: "root_path", permissao: "pessoas.ver", icone: "people")
  end

  it "levanta erro para módulo desconhecido" do
    expect { catalogo.modulo!(:nada) }.to raise_error(described_class::Erro, /módulo desconhecido: nada/)
  end

  describe "validação na carga" do
    it "exige nome" do
      expect { catalogo_com("permissoes: {}") }.to raise_error(described_class::Erro, /ruim.yml: falta o nome/)
    end

    it "recusa papel com permissão inexistente" do
      yaml = <<~YAML
        nome: Ruim
        permissoes: { a.ver: "Ver" }
        papeis: { admin: { nome: Admin, permissoes: [a.ver, a.apagar] } }
      YAML

      expect { catalogo_com(yaml) }.to raise_error(described_class::Erro, /papel admin usa permissões inexistentes: a.apagar/)
    end

    it "recusa concessão com papel inexistente" do
      yaml = <<~YAML
        nome: Ruim
        permissoes: { a.ver: "Ver" }
        papeis: { admin: { nome: Admin, permissoes: "*" } }
        concessao: { admin: [fantasma] }
      YAML

      expect { catalogo_com(yaml) }.to raise_error(described_class::Erro, /concessão cita papéis inexistentes: fantasma/)
    end

    it "recusa menu com permissão inexistente" do
      yaml = <<~YAML
        nome: Ruim
        permissoes: { a.ver: "Ver" }
        menu: [ { rotulo: X, rota: root_path, permissao: a.editar } ]
      YAML

      expect { catalogo_com(yaml) }.to raise_error(described_class::Erro, /menu X usa permissão inexistente: a.editar/)
    end
  end

  describe "catálogo real (config/modulos)" do
    it "carrega sem erros e tem o Core" do
      described_class.recarregar!

      expect(described_class.modulo(:core).papeis.keys).to include("superadmin", "admin_usuarios", "auditor")
      expect(described_class.permissao?("core.usuarios.gerenciar")).to be(true)
    end

    it "tem ícone existente para cada módulo e item de menu" do
      icones = described_class.modulos.flat_map { |m| [ m.icone, *m.menu.map(&:icone) ] }.compact

      icones.each { |nome| expect { IconesHelper.svg(nome.tr("_", "-")) }.not_to raise_error }
    end
  end
end
