require "rails_helper"

RSpec.describe "Transporte: motoristas e veículos" do
  def com_papel(papel) = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:tecnico) { com_papel("tecnico") }
  let(:dados) { { nome: "João da Silva", cpf: "529.982.247-25", data_nascimento: "15/01/1985", cnh_numero: "ab123456", cnh_categoria: "D", cnh_validade: "31/12/2030" } }

  it "quem não gerencia motoristas e veículos não entra" do
    sign_in com_papel("motorista")

    respostas = [ -> { get transporte_motoristas_path }, -> { post transporte_motoristas_path, params: { motorista: dados } },
                  -> { get transporte_veiculos_path }, -> { post transporte_veiculos_path, params: { veiculo: { placa: "QLM1A23" } } } ]
                .map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com técnico" do
    before { sign_in tecnico }

    describe "motoristas" do
      it "cadastra criando a conta, mostra a senha temporária uma vez e dá a permissão de motorista" do
        post transporte_motoristas_path, params: { motorista: dados.merge(email: "Joao@seed.ap.gov.br") }

        motorista = Transporte::Motorista.sole
        expect(response.body).to include("Conta de acesso criada", "joao@seed.ap.gov.br")
        expect(motorista).to have_attributes(nome: "JOÃO DA SILVA", cpf: "52998224725", cnh_numero: "AB123456", cnh_validade: Date.new(2030, 12, 31))
        expect(motorista.user).to have_attributes(email: "joao@seed.ap.gov.br", deve_trocar_senha: true)
        expect(Core::Autorizacao.new(motorista.user).pode?("transporte.servico.executar")).to be(true)
        expect(Core::RegistroAuditoria.where(modulo: "transporte").pluck(:evento)).to include("motorista.cadastrado")
      end

      it "liga à conta que já existe com o e-mail, sem criar outra" do
        conta = create(:user, email: "joao@seed.ap.gov.br")

        expect { post transporte_motoristas_path, params: { motorista: dados.merge(email: "joao@seed.ap.gov.br") } }.not_to change(User, :count)

        expect(response).to redirect_to(transporte_motoristas_path)
        expect(Transporte::Motorista.sole.user).to eq(conta)
      end

      it "não cria a conta quando os dados do motorista estão errados" do
        post transporte_motoristas_path, params: { motorista: dados.merge(email: "joao@seed.ap.gov.br", cpf: "111.111.111-11", cnh_categoria: "Z") }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Revise os campos destacados", "deve ser uma categoria válida")
        expect([ Transporte::Motorista.count, User.where(email: "joao@seed.ap.gov.br").count ]).to eq([ 0, 0 ])
      end

      it "exige o e-mail e não repete CPF nem conta" do
        outro = create(:transporte_motorista, cpf: "52998224725")

        post transporte_motoristas_path, params: { motorista: dados.merge(email: "") }
        expect(response.body).to include("E-mail não pode ficar em branco")

        post transporte_motoristas_path, params: { motorista: dados.merge(email: outro.user.email, cpf: "111.444.777-35") }
        expect(response.body).to include("E-mail já pertence a um motorista cadastrado")
        expect(Transporte::Motorista.count).to eq(1)
      end

      it "lista, busca, edita e desativa" do
        motorista = create(:transporte_motorista, nome: "João da Silva", cnh_validade: Date.yesterday)

        get transporte_motoristas_path, params: { q: "joao" }
        expect(response.body).to include("0 motorista(s)")
        get transporte_motoristas_path, params: { q: "joão" }
        expect(response.body).to include("1 motorista(s)", "JOÃO DA SILVA", "Vencida")

        patch transporte_motorista_path(motorista), params: { motorista: { cnh_validade: "01/01/2031" } }
        patch desativar_transporte_motorista_path(motorista)
        expect(motorista.reload).to have_attributes(cnh_validade: Date.new(2031, 1, 1), status: "inativo")

        # A lista abre em "Ativos" (como no seed); o inativo aparece em "Todos" e "Inativos".
        get transporte_motoristas_path
        expect(response.body).to include("0 motorista(s)")
        get transporte_motoristas_path, params: { status: "todos" }
        expect(response.body).to include("1 motorista(s)")
      end
    end

    describe "veículos" do
      let(:veiculo) { { placa: "qlm-1a23", marca: "Toyota", modelo: "Hilux", ano: 2022, cor: "Branca", capacidade: 4, combustivel: "diesel", consumo_km_por_litro: "9.5", odometro_atual: 12_000 } }

      it "cadastra com a placa normalizada e audita" do
        post transporte_veiculos_path, params: { veiculo: veiculo }

        expect(response).to redirect_to(transporte_veiculos_path)
        expect(Transporte::Veiculo.sole).to have_attributes(placa: "QLM1A23", marca: "TOYOTA", descricao: "QLM1A23 · TOYOTA HILUX", odometro_atual: 12_000)
        expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "transporte", evento: "veiculo.cadastrado")
      end

      it "recusa placa inválida ou repetida e números fora da faixa" do
        create(:transporte_veiculo, placa: "QLM1A23")

        post transporte_veiculos_path, params: { veiculo: veiculo }
        expect(response.body).to include("Placa já está em uso")

        post transporte_veiculos_path, params: { veiculo: veiculo.merge(placa: "12345", capacidade: 0, consumo_km_por_litro: 0) }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("deve ter o formato ABC1234 ou ABC1D23")
        expect(Transporte::Veiculo.count).to eq(1)
      end

      it "lista, busca, edita e desativa" do
        hilux = create(:transporte_veiculo, placa: "QLM1A23")
        create(:transporte_veiculo, placa: "ABC1234", marca: "Fiat", modelo: "Uno")

        get transporte_veiculos_path, params: { q: "hilux" }
        expect(response.body).to include("1 veículo(s)", "QLM1A23", "12.000 km")

        patch transporte_veiculo_path(hilux), params: { veiculo: { cor: "Prata" } }
        patch desativar_transporte_veiculo_path(hilux)
        expect(hilux.reload).to have_attributes(cor: "PRATA", status: "inativo")
      end
    end
  end
end
