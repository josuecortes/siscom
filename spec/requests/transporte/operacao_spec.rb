require "rails_helper"

RSpec.describe "Transporte: operação" do
  include ActiveSupport::Testing::TimeHelpers

  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:tecnico) { com_papel("tecnico", "TECNICO DO TRANSPORTE") }
  let(:dados) do
    { tipo: "normal", modo: "so_deixar", resumo: "Reunião na SEAD", saida_em: "08/10/2026 09:00", passageiros: [ { cpf: "529.982.247-25", nome: "Maria" } ],
      destinos: [ { nome: "SEAD", logradouro: "Avenida FAB", numero: "96", bairro: "Central", cidade: "Macapá", uf: "AP" } ] }
  end
  let!(:solicitacao) { Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados).objeto }

  before do
    Rh::Tabelas.garantir_padroes
    travel_to Time.zone.local(2026, 10, 5, 8, 0)
  end

  it "solicitante e motorista não entram na operação" do
    [ maria, com_papel("motorista", "MOTORISTA") ].each do |user|
      sign_in user
      respostas = [ -> { get transporte_operacao_index_path }, -> { patch aprovar_transporte_operacao_path(solicitacao) },
                    -> { get new_transporte_solicitacao_para_outro_path } ].map { |requisicao| requisicao.call && response.status }
      expect(respostas).to all(eq(403))
    end
    expect(solicitacao.reload).to be_solicitada
  end

  context "com técnico" do
    before { sign_in tecnico }

    it "lista todas as solicitações por etapa, com o solicitante e a ação de aprovar" do
      get transporte_operacao_index_path

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Operação de transporte", "1 solicitação(ões) em solicitadas", solicitacao.codigo, "MARIA OLIVEIRA", "Aprovar solicitação")
      expect(html.css("nav[aria-label='Etapas das solicitações'] a").map { |aba| aba.text.squish })
        .to eq([ "Solicitadas 1", "Aprovadas 0", "Em serviço 0", "Aguardando busca 0", "Concluídas 0", "Canceladas 0" ])
    end

    it "aprova e o solicitante é avisado" do
      patch aprovar_transporte_operacao_path(solicitacao)

      expect(solicitacao.reload).to have_attributes(status: "aprovada", aprovada_por: tecnico, aprovada_em: be_present)
      expect(maria.notificacoes.last).to have_attributes(titulo: "Solicitação de transporte aprovada")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "solicitacao.aprovada")

      patch aprovar_transporte_operacao_path(solicitacao)
      expect(flash[:alert]).to include("ainda está como solicitada")
    end

    it "reagenda a saída com motivo, avisa o solicitante e não aceita data no passado" do
      get reagendamento_transporte_operacao_path(solicitacao)
      expect(response.body).to include("Reagendar #{solicitacao.codigo}", "Saída atual: 08/10/2026 09:00")

      patch reagendar_transporte_operacao_path(solicitacao), params: { saida_em: "04/10/2026 09:00", motivo: "Veículo em manutenção" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Saída não pode estar no passado.")

      patch reagendar_transporte_operacao_path(solicitacao), params: { saida_em: "09/10/2026 14:30", motivo: "Veículo em manutenção" }
      expect(solicitacao.reload.saida_em).to eq(Time.zone.local(2026, 10, 9, 14, 30))
      expect(maria.notificacoes.last.mensagem).to include("nova saída em 09/10/2026 14:30", "Veículo em manutenção")
    end

    it "cancela com motivo, e a solicitação mostra o motivo" do
      patch cancelar_transporte_operacao_path(solicitacao), params: { motivo: " " }
      expect(response).to have_http_status(:unprocessable_content)

      patch cancelar_transporte_operacao_path(solicitacao), params: { motivo: "Sem veículo disponível" }
      expect(solicitacao.reload).to have_attributes(status: "cancelada", cancelada_por: tecnico, motivo_cancelamento: "Sem veículo disponível")
      expect(maria.notificacoes.last.titulo).to eq("Solicitação de transporte cancelada")

      get transporte_operacao_path(solicitacao)
      expect(response.body).to include("Sem veículo disponível", "Cancelada")
      expect(response.body).not_to include("O que fazer")
    end

    it "abre em nome de outra pessoa, inclusive fora do prazo" do
      get new_transporte_solicitacao_para_outro_path, params: { solicitacao: { solicitante_id: maria.id } }
      expect(response.body).to include("Solicitar transporte para outra pessoa", "Fora do prazo", 'value="MARIA OLIVEIRA"')

      post transporte_solicitacao_para_outro_path, params: { solicitacao: dados.merge(solicitante_id: maria.id, saida_em: "05/10/2026 14:00") }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("está fora do prazo para pedir")

      post transporte_solicitacao_para_outro_path, params: { solicitacao: dados.merge(solicitante_id: maria.id, saida_em: "05/10/2026 14:00", fora_do_padrao: "1") }
      nova = Transporte::Solicitacao.recentes.first
      expect(response).to redirect_to(transporte_operacao_path(nova))
      expect(nova).to have_attributes(solicitante: maria, aberto_por: tecnico, fora_do_padrao: true)
    end

    it "procura a pessoa por nome ou e-mail" do
      maria

      get pessoas_transporte_solicitacao_para_outro_path, params: { q: "maria" }

      expect(response.parsed_body["opcoes"].pluck("rotulo")).to eq([ "MARIA OLIVEIRA" ])
    end
  end

  describe "cancelamento pelo solicitante" do
    before { sign_in maria }

    it "cancela enquanto está solicitada ou aprovada, e a operação é avisada" do
      tecnico
      get transporte_solicitacao_path(solicitacao)
      expect(response.body).to include("Aguardando a aprovação do setor de transporte", "Cancelar solicitação")

      patch cancelar_transporte_solicitacao_path(solicitacao), params: { motivo: "Reunião desmarcada" }

      expect(solicitacao.reload).to have_attributes(status: "cancelada", cancelada_por: maria)
      expect(tecnico.notificacoes.last.titulo).to eq("Solicitação de transporte cancelada pelo solicitante")
    end

    it "depois que o serviço começou, só a operação cancela" do
      solicitacao.update!(status: "em_servico")

      patch cancelar_transporte_solicitacao_path(solicitacao), params: { motivo: "Desisti" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("só o setor de transporte pode cancelar agora")
    end
  end
end
