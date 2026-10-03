require "rails_helper"

RSpec.describe "RH: unidades" do
  let(:operador) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }
  let(:leitor) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "leitor") } }
  let(:sede) { create(:rh_tipo_unidade, nome: "Sede") }
  let(:tipo_escola) { create(:rh_tipo_unidade, nome: "Escola") }
  let!(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO", tipo_unidade: sede) }

  it "usuário comum (só papel automático) não vê unidades" do
    sign_in create(:user)

    get rh_unidades_path

    expect(response).to have_http_status(:forbidden)
  end

  it "leitor vê a lista mas não altera" do
    sign_in leitor

    get rh_unidades_path
    expect(response.body).to include("NÚCLEO DE INFORMÁTICA", "1 unidade(s) registrada(s)")
    expect(response.body).not_to include("Nova unidade")

    respostas = [
      -> { get new_rh_unidade_path },
      -> { post rh_unidades_path, params: { unidade: { nome: "X", sigla: "X", tipo_unidade_id: sede.id } } },
      -> { patch rh_unidade_path(nuinfo), params: { unidade: { nome: "Outro" } } },
      -> { patch desativar_rh_unidade_path(nuinfo) }
    ].map { |requisicao| requisicao.call && response.status }
    expect(respostas).to all(eq(403))
  end

  context "com operador" do
    before { sign_in operador }

    it "busca por nome ou sigla e mostra quantos estão lotados" do
      create(:rh_lotacao, unidade: nuinfo)
      create(:rh_unidade, nome: "Gabinete", sigla: "GAB")

      get rh_unidades_path, params: { q: "nuinfo" }

      expect(response.body).to include("1 unidade(s) registrada(s)", "NÚCLEO DE INFORMÁTICA")
      expect(response.body).not_to include("GABINETE")
    end

    it "cria unidade com unidade superior" do
      post rh_unidades_path, params: { unidade: { nome: "Divisão de Redes", sigla: "direde", tipo_unidade_id: sede.id, pai_id: nuinfo.id } }

      expect(response).to redirect_to(rh_unidades_path)
      expect(Rh::Unidade.find_by!(sigla: "DIREDE")).to have_attributes(nome: "DIVISÃO DE REDES", pai: nuinfo)
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "rh", evento: "unidade.criada", ator: operador)
    end

    it "cria escola sem sigla, com os dados da escola" do
      post rh_unidades_path, params: { unidade: { nome: "Escola Estadual A", sigla: "", tipo_unidade_id: tipo_escola.id,
                                                  dados_escola: { nae: "NAE 1", codigo_inep: "16000001", endereco: "Rua A, 10" } } }

      escola = Rh::Unidade.find_by!(nome: "ESCOLA ESTADUAL A")
      expect(escola.dados_escola).to have_attributes(nae: "NAE 1", codigo_inep: "16000001", endereco: "Rua A, 10")
    end

    it "ignora os dados de escola em unidade que não é escola" do
      patch rh_unidade_path(nuinfo), params: { unidade: { nome: "Núcleo de TI", dados_escola: { nae: "X" } } }

      expect(nuinfo.reload).to have_attributes(nome: "NÚCLEO DE TI", dados_escola: nil)
    end

    it "mostra os erros com 422" do
      post rh_unidades_path, params: { unidade: { nome: "", sigla: "nuinfo", tipo_unidade_id: sede.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome não pode ficar em branco", "Sigla já está em uso")
    end

    it "não deixa a unidade virar filha de uma unidade abaixo dela" do
      filha = create(:rh_unidade, pai: nuinfo)

      patch rh_unidade_path(nuinfo), params: { unidade: { pai_id: filha.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Unidade superior não pode ser uma unidade abaixo desta")
    end

    it "desativa e reativa, mas não desativa unidade com lotação ativa" do
      patch desativar_rh_unidade_path(nuinfo)
      expect(nuinfo.reload).to be_inativo
      patch ativar_rh_unidade_path(nuinfo)
      expect(nuinfo.reload).to be_ativo

      create(:rh_lotacao, unidade: nuinfo)
      patch desativar_rh_unidade_path(nuinfo)
      expect(flash[:alert]).to include("1 lotação(ões) ativa(s)")
      expect(nuinfo.reload).to be_ativo
    end
  end
end
