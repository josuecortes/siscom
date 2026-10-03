require "rails_helper"

RSpec.describe "RH: pessoas, ficha e lotações" do
  let(:operador) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }
  let(:leitor) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "leitor") } }
  let(:nuinfo) { create(:rh_unidade, sigla: "NUINFO", nome: "Núcleo de Informática") }
  let(:tecnico) { create(:rh_funcao, nome: "Técnico") }
  let!(:maria) { create(:rh_pessoa, nome: "Maria Oliveira", email: "maria@seed.ap.gov.br", cpf: "52998224725", user: create(:user, email: "maria@seed.ap.gov.br")) }

  it "usuário comum não vê pessoas nem lotações, mas vê a própria ficha" do
    sign_in maria.user
    create(:rh_lotacao, pessoa: maria, unidade: nuinfo, funcao: tecnico)

    get rh_pessoas_path
    expect(response).to have_http_status(:forbidden)
    get rh_lotacoes_path
    expect(response).to have_http_status(:forbidden)
    get rh_pessoa_path(maria)
    expect(response).to have_http_status(:forbidden)

    get rh_minha_ficha_path
    expect(response.body).to include("Minha ficha", "MARIA OLIVEIRA", "529.982.247-25", "NUINFO - NÚCLEO DE INFORMÁTICA")
    expect(response.body).not_to include("Nova lotação", "Encerrar lotação")
  end

  it "quem não tem ficha vê o aviso" do
    sign_in create(:user)

    get rh_minha_ficha_path

    expect(response.body).to include("Você ainda não tem ficha no RH.")
  end

  it "leitor consulta, mas não cadastra, edita, lota nem encerra" do
    lotacao = create(:rh_lotacao, pessoa: maria, unidade: nuinfo, funcao: tecnico)
    sign_in leitor

    get rh_pessoas_path
    expect(response.body).to include("MARIA OLIVEIRA", "1 pessoa(s) registrada(s)")
    get rh_pessoa_path(maria)
    expect(response.body).not_to include("Nova lotação")

    respostas = [
      -> { get new_rh_pessoa_path },
      -> { post rh_pessoas_path, params: { pessoa: { nome: "X Y", email: "x@seed.ap.gov.br" } } },
      -> { patch rh_pessoa_path(maria), params: { pessoa: { nome: "Outro Nome" } } },
      -> { get new_rh_pessoa_lotacao_path(maria) },
      -> { post rh_pessoa_lotacoes_path(maria), params: { lotacao: { unidade_id: nuinfo.id, funcao_id: tecnico.id } } },
      -> { patch encerrar_rh_lotacao_path(lotacao) }
    ].map { |requisicao| requisicao.call && response.status }
    expect(respostas).to all(eq(403))
    expect(lotacao.reload).to be_ativo
  end

  context "com operador" do
    before { sign_in operador }

    it "busca por nome, e-mail ou CPF e filtra por situação" do
      create(:rh_pessoa, nome: "Joao Santos")
      create(:rh_lotacao, pessoa: maria, unidade: nuinfo, funcao: tecnico)
      Rh::PendenciaImportacao.create!(pessoa: maria, tipo: "cpf_invalido", descricao: "x")

      get rh_pessoas_path, params: { q: "529.982" }
      expect(response.body).to include("1 pessoa(s) registrada(s)", "MARIA OLIVEIRA", "NUINFO - NÚCLEO DE INFORMÁTICA", "Pendência")

      get rh_pessoas_path, params: { situacao: "sem_lotacao" }
      expect(response.body).to include("JOAO SANTOS")
      expect(response.body).not_to include("MARIA OLIVEIRA")

      get rh_pessoas_path, params: { situacao: "com_pendencia" }
      expect(response.body).to include("MARIA OLIVEIRA")
      expect(response.body).not_to include("JOAO SANTOS")
    end

    it "cadastra, mostra a senha da conta uma única vez e abre a ficha" do
      post rh_pessoas_path, params: { pessoa: { nome: "Ana Paula Lima", email: "ana@seed.ap.gov.br", celular: "96991234567", cpf: "111.444.777-35",
                                                data_nascimento: "02/03/1990", sexo: "feminino" } }

      ana = Rh::Pessoa.find_by!(email: "ana@seed.ap.gov.br")
      senha = response.body[%r{data-senha-temporaria>([^<]+)<}, 1]
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(ana.user.valid_password?(senha)).to be(true)

      get rh_pessoa_path(ana)
      expect(response.body).to include("ANA PAULA LIMA", "111.444.777-35", "(96) 99123-4567", "02/03/1990", "Feminino", "Nenhuma lotação registrada.")
    end

    it "mostra os erros por campo com 422 e devolve a data como foi digitada" do
      post rh_pessoas_path, params: { pessoa: { nome: "Ana", email: "maria@seed.ap.gov.br", celular: "", cpf: "123", data_nascimento: "31/02/1990" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Revise os campos destacados", "Nome completo deve ter nome e sobrenome", "E-mail já está em uso",
                                       "Celular não pode ficar em branco", "CPF não é válido", 'value="31/02/1990"',
                                       "Data de nascimento não é uma data válida")
    end

    it "edita e mostra o formulário com CPF, celular e data formatados" do
      maria.update!(celular: "96991234567", data_nascimento: Date.new(1985, 1, 15))

      get edit_rh_pessoa_path(maria)
      expect(response.body).to include('value="529.982.247-25"', 'value="(96) 99123-4567"', 'value="15/01/1985"')

      patch rh_pessoa_path(maria), params: { pessoa: { nome: "Maria Oliveira Souza" } }
      expect(response).to redirect_to(rh_pessoa_path(maria))
      expect(maria.reload.nome).to eq("MARIA OLIVEIRA SOUZA")
    end

    it "lota pela ficha e encerra a lotação" do
      post rh_pessoa_lotacoes_path(maria), params: { lotacao: { unidade_id: nuinfo.id, funcao_id: tecnico.id, data_inicio: "01/03/2024" } }
      expect(response).to redirect_to(rh_pessoa_path(maria))
      lotacao = maria.lotacoes.sole

      get rh_lotacoes_path, params: { q: "nuinfo" }
      expect(response.body).to include("1 lotação(ões) registrada(s)", "MARIA OLIVEIRA", "01/03/2024")

      patch encerrar_rh_lotacao_path(lotacao)
      expect(lotacao.reload).to be_inativo

      get rh_lotacoes_path
      expect(response.body).to include("0 lotação(ões) registrada(s)")
      get rh_lotacoes_path, params: { status: "inativo" }
      expect(response.body).to include("Encerrada", Date.current.strftime("%d/%m/%Y"))
    end

    it "mostra o erro de lotação repetida com 422" do
      create(:rh_lotacao, pessoa: maria, unidade: nuinfo, funcao: tecnico)

      post rh_pessoa_lotacoes_path(maria), params: { lotacao: { unidade_id: nuinfo.id, funcao_id: tecnico.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("já existe uma lotação ativa")
    end
  end
end
