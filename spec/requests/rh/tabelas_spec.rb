require "rails_helper"

RSpec.describe "RH: tabelas de referência" do
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") } }
  let(:operador) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }

  it "só o administrador do RH gerencia as tabelas" do
    cargo = create(:rh_cargo)
    sign_in operador

    respostas = [
      -> { get rh_cargos_path },
      -> { post rh_cargos_path, params: { registro: { nome: "X" } } },
      -> { patch desativar_rh_cargo_path(cargo) }
    ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com administrador do RH" do
    before { sign_in admin }

    it "abre as cinco tabelas pela mesma tela" do
      { rh_tipos_vinculo_path => "Vínculos", rh_cargos_path => "Cargos", rh_funcoes_path => "Funções de lotação",
        rh_tipos_unidade_path => "Tipos de unidade", rh_tipos_local_path => "Locais físicos" }.each do |caminho, titulo|
        get caminho
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<title>#{titulo} · Siscom</title>")
      end
    end

    it "lista, busca e filtra por status" do
      create(:rh_cargo, nome: "Analista")
      create(:rh_cargo, nome: "Professor", status: "inativo")

      get rh_cargos_path
      expect(response.body).to include("2 cargo(s) registrado(s)", "ANALISTA", "PROFESSOR")

      get rh_cargos_path, params: { q: "anal" }
      expect(response.body).to include("1 cargo(s) registrado(s)")

      get rh_cargos_path, params: { status: "inativo" }
      expect(response.body).to include("PROFESSOR")
      expect(response.body).not_to include("ANALISTA")
    end

    it "cria, edita e muda o status, com auditoria" do
      post rh_funcoes_path, params: { registro: { nome: "chefe de núcleo", descricao: "Chefia" } }
      funcao = Rh::Funcao.find_by!(nome: "CHEFE DE NÚCLEO")
      expect(response).to redirect_to(rh_funcoes_path)

      patch rh_funcao_path(funcao), params: { registro: { nome: "Chefe de Núcleo I" } }
      patch desativar_rh_funcao_path(funcao)

      expect(funcao.reload).to have_attributes(nome: "CHEFE DE NÚCLEO I", descricao: "Chefia", status: "inativo")
      expect(Core::RegistroAuditoria.where(modulo: "rh").order(:id).pluck(:evento)).to eq(%w[tabela.criada tabela.atualizada tabela.desativada])
    end

    it "mostra erro de nome repetido com 422" do
      create(:rh_cargo, nome: "Analista")

      post rh_cargos_path, params: { registro: { nome: "analista" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome já está em uso")
    end

    it "ignora descrição em tabela que não tem esse campo" do
      post rh_cargos_path, params: { registro: { nome: "Técnico", descricao: "não existe" } }

      expect(Rh::Cargo.find_by!(nome: "TÉCNICO")).to be_ativo
    end
  end

  it "cria as opções Não informado de vínculo e local" do
    2.times { Rh::Tabelas.garantir_padroes }

    expect([ Rh::TipoVinculo.pluck(:nome), Rh::TipoLocal.pluck(:nome) ]).to eq([ [ "NÃO INFORMADO" ], [ "NÃO INFORMADO" ] ])
  end
end
