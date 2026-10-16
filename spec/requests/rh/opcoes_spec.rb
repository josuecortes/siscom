require "rails_helper"

RSpec.describe "RH: opções dos campos de busca (autocomplete)" do
  let(:operador) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }

  def opcoes(fonte, **parametros)
    get rh_opcoes_path(fonte), params: parametros
    response.parsed_body
  end

  it "exige permissão de gerenciar algo no RH" do
    leitor = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "leitor") }
    sign_in leitor

    get rh_opcoes_path("cargos")

    expect(response).to have_http_status(:forbidden)
  end

  context "com operador" do
    before do
      sign_in operador
      %w[Estadual Federal Estagiário Contrato].each { |nome| create(:rh_tipo_vinculo, nome: nome) }
      create(:rh_tipo_vinculo, nome: "Extinto", status: "inativo")
    end

    it "sem texto (ou com menos de 3 letras) devolve a lista ativa em ordem alfabética" do
      expect(opcoes("tipos_vinculo")["opcoes"].pluck("rotulo")).to eq(%w[CONTRATO ESTADUAL ESTAGIÁRIO FEDERAL])
      expect(opcoes("tipos_vinculo", q: "es")).to include("todas" => true, "restantes" => 0)
    end

    it "com 3 letras ou mais devolve só o que combina" do
      resposta = opcoes("tipos_vinculo", q: "est")

      expect(resposta["opcoes"].pluck("rotulo")).to eq(%w[ESTADUAL ESTAGIÁRIO])
      expect(resposta["todas"]).to be(false)
    end

    it "quando nada combina, devolve a lista completa em ordem alfabética" do
      resposta = opcoes("tipos_vinculo", q: "xyz")

      expect(resposta["opcoes"].pluck("rotulo")).to eq(%w[CONTRATO ESTADUAL ESTAGIÁRIO FEDERAL])
      expect(resposta["todas"]).to be(true)
    end

    it "serve cargos, funções, unidades (sem a própria) e pessoas" do
      create(:rh_cargo, nome: "Analista")
      create(:rh_funcao, nome: "Técnico")
      nuinfo = create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
      create(:rh_unidade, nome: "Gabinete", sigla: "GAB")
      create(:rh_pessoa, nome: "Maria Oliveira", email: "maria@seed.ap.gov.br")

      expect(opcoes("cargos")["opcoes"]).to eq([ { "valor" => Rh::Cargo.sole.id, "rotulo" => "ANALISTA" } ])
      expect(opcoes("funcoes", q: "téc")["opcoes"].pluck("rotulo")).to eq([ "TÉCNICO" ])
      expect(opcoes("unidades", q: "nuinfo")["opcoes"].pluck("rotulo")).to eq([ "NUINFO - NÚCLEO DE INFORMÁTICA" ])
      expect(opcoes("unidades", exceto: nuinfo.id)["opcoes"].pluck("rotulo")).to eq([ "GAB - GABINETE" ])
      expect(opcoes("pessoas", q: "maria")["opcoes"]).to eq([ { "valor" => Rh::Pessoa.sole.id, "rotulo" => "MARIA OLIVEIRA", "subtitulo" => "maria@seed.ap.gov.br" } ])
    end

    it "limita listas grandes e diz quantas ficaram de fora" do
      create_list(:rh_cargo, 53)

      resposta = opcoes("cargos")

      expect(resposta["opcoes"].size).to eq(50)
      expect(resposta["restantes"]).to eq(3)
    end

    it "responde 404 para fonte desconhecida" do
      get rh_opcoes_path("senhas")

      expect(response).to have_http_status(:not_found)
    end
  end
end
