require "rails_helper"

RSpec.describe "Transporte: permissões e configuração" do
  def com_papel(papel) = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:admin) { com_papel("admin") }
  let(:tecnico) { com_papel("tecnico") }
  let!(:maria) { create(:user, nome: "MARIA OLIVEIRA") }

  def concedidos = Core::Api.papeis_concedidos([ maria.id ], modulo: :transporte).fetch(maria.id, [])

  it "só pede transporte quem tem permissão; técnico e motorista somam o que cabe a cada um" do
    pode = ->(user, permissao) { Core::Autorizacao.new(user).pode?("transporte.#{permissao}") }

    expect(Core::Autorizacao.new(maria).papeis(:transporte)).to be_empty
    expect([ pode.call(maria, "solicitacoes.abrir"), pode.call(com_papel("solicitante"), "solicitacoes.abrir") ]).to eq([ false, true ])
    expect(%w[solicitacoes.aprovar motoristas.gerenciar configuracoes.gerenciar servico.executar].map { |p| pode.call(tecnico, p) }).to eq([ true, true, false, false ])
    expect(%w[servico.executar solicitacoes.aprovar].map { |p| pode.call(com_papel("motorista"), p) }).to eq([ true, false ])
  end

  it "o técnico dá a permissão de solicitante e de motorista, mas não a de técnico; e não muda a configuração" do
    sign_in tecnico

    patch transporte_permissao_path(maria), params: { papeis: [ "", "solicitante", "motorista" ] }
    expect(concedidos).to contain_exactly("solicitante", "motorista")

    patch transporte_permissao_path(maria), params: { papeis: [ "", "solicitante", "motorista", "tecnico" ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(concedidos).not_to include("tecnico")

    get transporte_configuracoes_path
    expect(response).to have_http_status(:forbidden)
  end

  it "converte os papéis antigos: requisitante vira solicitante e técnico continua técnico" do
    antigo_tecnico = create(:user)
    dar_papel_antigo(maria, "req_serv_tp")
    dar_papel_antigo(antigo_tecnico, "tec_serv_tp")

    Core::Api.importar_papeis("req_serv_tp" => [ %w[transporte solicitante] ], "tec_serv_tp" => [ %w[transporte tecnico] ])

    expect(concedidos).to eq([ "solicitante" ])
    expect(Core::Autorizacao.new(antigo_tecnico).papeis(:transporte)).to eq([ "tecnico" ])
  end

  context "com administrador do Transporte" do
    before { sign_in admin }

    it "lista os usuários e acumula permissões (técnico e motorista)" do
      get transporte_permissoes_path
      expect(response.body).to include("MARIA OLIVEIRA", "Sem permissão")

      get edit_transporte_permissao_path(maria)
      expect(response.body).to include("Gerenciar permissões de MARIA OLIVEIRA", "Administrador", "Técnico", "Motorista", "Solicitante")

      patch transporte_permissao_path(maria), params: { papeis: [ "", "tecnico", "motorista" ] }
      expect(concedidos).to contain_exactly("tecnico", "motorista")
      expect(maria.notificacoes.pluck(:mensagem).join).to include("no módulo Transporte")
    end

    it "mostra a configuração com os padrões do seed e salva com auditoria" do
      get transporte_configuracoes_path
      expect(response.body).to include("Antecedência para pedir", "Tempo no destino", "Alertas", 'value="48"', 'value="30"')

      patch transporte_configuracoes_path, params: { configuracao: { normal_antecedencia_min_horas: 24, lembrete_saida_minutos: 45 } }

      expect(response).to redirect_to(transporte_configuracoes_path)
      expect(Transporte::Configuracao.atual).to have_attributes(normal_antecedencia_min_horas: 24, lembrete_saida_minutos: 45, busca_max_horas: 24)
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "transporte", evento: "configuracao.atualizada")
    end

    it "recusa mínimo maior que o máximo e valores inválidos, com 422" do
      patch transporte_configuracoes_path, params: { configuracao: { espera_min_horas: 5, espera_max_horas: 2, lembrete_saida_minutos: 0 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("deve ser maior ou igual ao mínimo", "Revise os campos destacados")
      expect(Transporte::Configuracao.atual.espera_min_horas).to eq(1)
    end
  end
end
