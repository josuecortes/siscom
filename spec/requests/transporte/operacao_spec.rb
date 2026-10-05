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
  let(:solicitacao) { Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados).objeto }

  # O relógio é fixado antes de criar a solicitação: senão ela nasce com a hora de verdade, que pode
  # ser depois da hora fixada, e a ordem "mais recente primeiro" fica trocada.
  before do
    Rh::Tabelas.garantir_padroes
    travel_to Time.zone.local(2026, 10, 5, 8, 0)
    solicitacao
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
        .to eq([ "Solicitadas 1", "Aprovadas 0", "Reagendadas 0", "Em serviço 0", "Aguardando busca 0", "Concluídas 0", "Canceladas 0" ])
      # As ações ficam na linha; "ver" abre no painel, nunca numa página.
      expect(html.css("tr##{ActionView::RecordIdentifier.dom_id(solicitacao)} td:last-child [title]").pluck("title"))
        .to eq([ "Visualizar solicitação", "Aprovar solicitação", "Registrar observação", "Cancelar solicitação" ])
      expect(html.at_css("a[title='Visualizar solicitação']")["data-turbo-frame"]).to eq("painel")
    end

    it "aprova e o solicitante é avisado" do
      patch aprovar_transporte_operacao_path(solicitacao)

      expect(solicitacao.reload).to have_attributes(status: "aprovada", aprovada_por: tecnico, aprovada_em: be_present)
      expect(maria.notificacoes.last).to have_attributes(titulo: "Solicitação de transporte aprovada")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "solicitacao.aprovada")

      patch aprovar_transporte_operacao_path(solicitacao)
      expect(flash[:alert]).to include("ainda está como solicitada")
    end

    it "só reagenda a solicitação aprovada, com data futura, motivo e horário diferente" do
      respostas = lambda do |parametros|
        patch reagendar_transporte_operacao_path(solicitacao), params: parametros
        [ response.status, Nokogiri::HTML(response.body).at_css("[data-faixa-aviso='erro']").text.squish ]
      end

      expect(respostas.call(saida_em: "09/10/2026 14:30", motivo: "Veículo em manutenção").last).to include("Só dá para reagendar uma solicitação aprovada")

      solicitacao.update!(status: "aprovada")
      get reagendamento_transporte_operacao_path(solicitacao)
      expect(response.body).to include("Reagendar #{solicitacao.codigo}", "Saída atual: 08/10/2026 09:00", "até o solicitante aceitar ou recusar")
      expect([ { saida_em: "04/10/2026 09:00", motivo: "Veículo em manutenção" }, { saida_em: "09/10/2026 14:30", motivo: " " },
               { saida_em: "08/10/2026 09:00", motivo: "Nada mudou" } ].map { |parametros| respostas.call(parametros) })
        .to eq([ [ 422, "Saída não pode estar no passado." ], [ 422, "Motivo deve ser preenchido." ], [ 422, "Mude a saída ou o retorno para reagendar." ] ])
      expect(solicitacao.reload).to be_aprovada
    end

    it "reagendada, a solicitação espera a resposta do solicitante, que é avisado; fica no histórico" do
      solicitacao.update!(status: "aprovada")

      patch reagendar_transporte_operacao_path(solicitacao), params: { saida_em: "09/10/2026 14:30", motivo: "Veículo em manutenção" }

      expect(solicitacao.reload).to have_attributes(status: "reagendada", saida_em: Time.zone.local(2026, 10, 9, 14, 30), saida_anterior_em: Time.zone.local(2026, 10, 8, 9, 0),
                                                    motivo_reagendamento: "Veículo em manutenção", reagendada_por: tecnico)
      expect(maria.notificacoes.last).to have_attributes(titulo: "Reagendamento aguardando a sua resposta")
      expect(solicitacao.eventos.em_ordem.last).to have_attributes(tipo: "reagendada", ator_nome: "TECNICO DO TRANSPORTE",
                                                                   nota: "Saída de 08/10/2026 09:00 para 09/10/2026 14:30. Motivo: Veículo em manutenção")

      patch reagendar_transporte_operacao_path(solicitacao), params: { saida_em: "10/10/2026 08:00", motivo: "De novo" }
      expect(response.body).to include("aguarda a resposta do solicitante")
    end

    it "reagenda a previsão da busca quando a solicitação está aguardando busca" do
      solicitacao.update!(status: "busca", modo: "buscar_depois", busca_horas: 2, busca_prevista_em: Time.zone.local(2026, 10, 8, 11, 0), ultimo_aviso_de_busca_em: Time.current)

      get reagendamento_transporte_operacao_path(solicitacao)
      expect(response.body).to include("Nova previsão da busca (data e hora) *", "Busca prevista: 08/10/2026 11:00")

      patch reagendar_transporte_operacao_path(solicitacao), params: { busca_em: "08/10/2026 13:30", motivo: "Reunião se estendeu" }
      expect(solicitacao.reload).to have_attributes(busca_prevista_em: Time.zone.local(2026, 10, 8, 13, 30), ultimo_aviso_de_busca_em: nil)
      expect(maria.notificacoes.last.titulo).to eq("Busca reagendada")
    end

    it "cancela com motivo, e a solicitação mostra o motivo" do
      patch cancelar_transporte_operacao_path(solicitacao), params: { motivo: " " }
      expect(response).to have_http_status(:unprocessable_content)

      patch cancelar_transporte_operacao_path(solicitacao), params: { motivo: "Sem veículo disponível" }
      expect(solicitacao.reload).to have_attributes(status: "cancelada", cancelada_por: tecnico, motivo_cancelamento: "Sem veículo disponível")
      expect(maria.notificacoes.last.titulo).to eq("Solicitação de transporte cancelada")

      ver_no_painel transporte_operacao_path(solicitacao)
      expect(response.body).to include("Sem veículo disponível", "Cancelada", "Solicitação cancelada")
    end

    it "abre em nome de outra pessoa, inclusive fora do prazo" do
      get new_transporte_solicitacao_para_outro_path, params: { solicitacao: { solicitante_id: maria.id } }
      expect(response.body).to include("Solicitar transporte para outra pessoa", "Fora do prazo", 'value="MARIA OLIVEIRA"')

      post transporte_solicitacao_para_outro_path, params: { solicitacao: dados.merge(solicitante_id: maria.id, saida_em: "05/10/2026 14:00") }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("está fora do prazo para pedir")

      post transporte_solicitacao_para_outro_path, params: { solicitacao: dados.merge(solicitante_id: maria.id, saida_em: "05/10/2026 14:00", fora_do_padrao: "1") }
      nova = Transporte::Solicitacao.recentes.first
      expect(response).to redirect_to(transporte_operacao_index_path)
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
      get transporte_solicitacoes_path
      expect(response.body).to include("Cancelar solicitação")

      patch cancelar_transporte_solicitacao_path(solicitacao), params: { motivo: "Reunião desmarcada" }

      expect(solicitacao.reload).to have_attributes(status: "cancelada", cancelada_por: maria)
      expect(tecnico.notificacoes.last.titulo).to eq("Solicitação de transporte cancelada pelo solicitante")
    end

    it "aceita o reagendamento: a solicitação volta a ficar aprovada com o novo horário" do
      solicitacao.update!(status: "aprovada")
      Transporte::Solicitacoes::Reagendar.call(solicitacao: solicitacao, ator: tecnico, saida_em: "09/10/2026 14:30", motivo: "Veículo em manutenção")

      get transporte_solicitacoes_path, params: { status: "reagendada" }
      expect(response.body).to include("Responder ao reagendamento", "Reagendada")
      ver_no_painel reagendamento_transporte_solicitacao_path(solicitacao)
      expect(response.body).to include("Reagendamento de #{solicitacao.codigo}", "08/10/2026 09:00", "09/10/2026 14:30", "Veículo em manutenção", "TECNICO DO TRANSPORTE",
                                       "Aceitar novo horário", "Recusar")

      patch responder_reagendamento_transporte_solicitacao_path(solicitacao), params: { resposta: "aceitar" }

      expect(solicitacao.reload).to have_attributes(status: "aprovada", saida_em: Time.zone.local(2026, 10, 9, 14, 30), reagendamento_respondido_em: be_present)
      expect(tecnico.notificacoes.last.titulo).to eq("Reagendamento aceito")
      expect(solicitacao.eventos.em_ordem.pluck(:tipo)).to eq(%w[aberta reagendada reagendamento_aceito])
    end

    it "recusa o reagendamento só com motivo: os horários antigos voltam e a solicitação é cancelada" do
      solicitacao.update!(status: "aprovada")
      Transporte::Solicitacoes::Reagendar.call(solicitacao: solicitacao, ator: tecnico, saida_em: "09/10/2026 14:30", motivo: "Veículo em manutenção")

      patch responder_reagendamento_transporte_solicitacao_path(solicitacao), params: { resposta: "recusar", motivo: " " }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Motivo deve ser preenchido.")

      patch responder_reagendamento_transporte_solicitacao_path(solicitacao), params: { resposta: "recusar", motivo: "Nesse dia não posso" }

      expect(solicitacao.reload).to have_attributes(status: "cancelada", saida_em: Time.zone.local(2026, 10, 8, 9, 0), motivo_recusa_reagendamento: "Nesse dia não posso",
                                                    cancelada_por: maria, motivo_cancelamento: "Reagendamento recusado pelo solicitante: Nesse dia não posso")
      expect(tecnico.notificacoes.last).to have_attributes(titulo: "Reagendamento recusado")
      expect(solicitacao.eventos.em_ordem.last).to have_attributes(tipo: "reagendamento_recusado", ator_nome: "MARIA OLIVEIRA")
    end

    it "só o solicitante responde, e só enquanto está reagendada" do
      patch responder_reagendamento_transporte_solicitacao_path(solicitacao), params: { resposta: "aceitar" }
      expect(response.body).to include("Não há reagendamento aguardando resposta")

      sign_in tecnico
      patch responder_reagendamento_transporte_solicitacao_path(solicitacao), params: { resposta: "aceitar" }
      expect(response).to have_http_status(:not_found)
    end

    it "depois que o serviço começou, só a operação cancela" do
      solicitacao.update!(status: "em_servico")

      patch cancelar_transporte_solicitacao_path(solicitacao), params: { motivo: "Desisti" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("só o setor de transporte pode cancelar agora")
    end
  end
end
