require "rails_helper"

RSpec.describe Fronteiras do
  it "nenhum módulo usa constantes internas de outro (só <Modulo>::Api)" do
    violacoes = described_class.violacoes

    expect(violacoes).to be_empty, "Fronteiras violadas:\n#{violacoes.map { |v| "  #{v}" }.join("\n")}"
  end

  describe ".violacoes_em" do
    def referencias(codigo, modulo: "Ti")
      described_class.violacoes_em(codigo, modulo: modulo).map(&:referencia)
    end

    it "permite a Api de outro módulo e as constantes do próprio módulo" do
      codigo = <<~RUBY
        unidade = Rh::Api.unidade_atual(user)
        ::Core::Api.notificar(user)
        Ti::Chamado.create!(rh_unidade_id: unidade.id)
      RUBY

      expect(referencias(codigo)).to be_empty
    end

    it "permite a infraestrutura pública do Core" do
      codigo = <<~RUBY
        class Ti::ChamadoPolicy < Core::PoliticaBase; end
        include Core::ExigeModulo
        Core::Resultado.sucesso(chamado)
      RUBY

      expect(referencias(codigo)).to be_empty
    end

    it "acusa model ou service interno de outro módulo" do
      codigo = <<~RUBY
        Rh::Pessoa.find(id)
        ::Core::Concessao.where(user: user)
        Transporte::Solicitacoes::Criar.call
      RUBY

      expect(referencias(codigo)).to eq(%w[Rh::Pessoa Core::Concessao Transporte::Solicitacoes])
    end

    it "informa arquivo e linha, e ignora comentários" do
      codigo = "# Rh::Pessoa em comentário\nx = 1\nRh::Unidade.all\n"
      violacao = described_class.violacoes_em(codigo, modulo: "Ti", arquivo: "app/models/ti/chamado.rb").sole

      expect(violacao.to_s).to eq("app/models/ti/chamado.rb:3 usa Rh::Unidade")
    end

    it "não confunde nomes que apenas contêm o nome de um módulo" do
      expect(referencias("MeuRh::Pessoa.new; Outro::Core::Coisa")).to be_empty
    end
  end

  describe ".arquivos_do" do
    it "encontra os arquivos do módulo em app/" do
      arquivos = described_class.arquivos_do("Core").map { |a| Pathname(a).relative_path_from(Rails.root).to_s }

      expect(arquivos).to include("app/models/core.rb", "app/services/core/api.rb", "app/services/core/catalogo.rb")
    end
  end
end
