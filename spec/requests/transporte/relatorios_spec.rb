require "rails_helper"

RSpec.describe "Transporte: relatórios" do
  include ActiveSupport::Testing::TimeHelpers

  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:tecnico) { com_papel("tecnico", "TECNICO") }
  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:joao) { com_papel("motorista", "JOAO MOTORISTA") }
  let(:hilux) { create(:transporte_veiculo, placa: "QLM1A23", odometro_atual: 12_000, consumo_km_por_litro: 10) }

  def solicitacao(**atributos)
    Transporte::Solicitacao.create!({ tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Reunião", saida_em: Time.current, solicitante: maria,
                                      solicitante_nome: maria.nome, solicitante_email: maria.email }.merge(atributos))
  end

  before do
    travel_to Time.zone.local(2026, 10, 8, 9, 0)
    primeira, segunda = solicitacao, solicitacao(resumo: "Entrega")
    Transporte::Servicos::Iniciar.call(solicitacao: primeira, ator: joao, veiculo_id: hilux.id, odometro: 12_000, outras_ids: [ segunda.id ])
    Transporte::Servicos::Finalizar.call(solicitacao: primeira, ator: joao, odometro: 12_030)
    Transporte::Servicos::Finalizar.call(solicitacao: segunda, ator: joao, odometro: 12_050)
    solicitacao(status: "cancelada", saida_em: 10.days.ago)
  end

  it "só quem vê relatórios entra" do
    sign_in maria

    get transporte_relatorios_path

    expect(response).to have_http_status(:forbidden)
  end

  context "com técnico" do
    before { sign_in tecnico }

    it "lista as solicitações do período com o resumo por status" do
      get transporte_relatorios_path, params: { inicio: "01/10/2026", fim: "31/10/2026" }

      expect(response.body).to include("Relatórios", "2 registro(s) de 01/10/2026 a 31/10/2026", "MARIA OLIVEIRA", "JOAO MOTORISTA", "QLM1A23", "Concluída", "Exportar Excel")
      expect(Nokogiri::HTML(response.body).css("tbody").text).not_to include("Cancelada")

      get transporte_relatorios_path, params: { inicio: "01/09/2026", fim: "31/10/2026", status: "cancelada" }
      expect(response.body).to include("1 registro(s)")
    end

    it "por veículo e por motorista, a saída em grupo conta como uma viagem e os quilômetros não dobram" do
      veiculos = Transporte::Relatorios::Consultar.call(tipo: "veiculos", filtros: { inicio: "01/10/2026", fim: "31/10/2026" })
      motoristas = Transporte::Relatorios::Consultar.call(tipo: "motoristas", filtros: { inicio: "01/10/2026", fim: "31/10/2026" })

      expect(veiculos.linhas).to eq([ [ "QLM1A23", "TOYOTA HILUX", 1, 2, 50, 5.0, 12_050 ] ])
      expect(veiculos.resumo).to include("Viagens" => 1, "Km rodados" => 50, "Litros estimados" => 5.0)
      expect(motoristas.linhas).to eq([ [ "JOAO MOTORISTA", 1, 2, 50, "QLM1A23" ] ])

      get transporte_relatorios_path, params: { tipo: "veiculos", inicio: "01/10/2026", fim: "31/10/2026" }
      expect(response.body).to include("Km rodados", "Litros estimados", "TOYOTA HILUX")
    end

    it "exporta para Excel e registra na auditoria" do
      get transporte_relatorios_path(format: :xlsx), params: { tipo: "motoristas", inicio: "01/10/2026", fim: "31/10/2026" }

      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(response.headers["Content-Disposition"]).to include("transporte-motoristas-")
      expect(response.body.byteslice(0, 2)).to eq("PK")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "transporte", evento: "relatorio.exportado")
    end

    it "o Excel obedece os filtros, e o botão Exportar envia o formulário de filtros" do
      aprovada = solicitacao.codigo
      cancelada = solicitacao(status: "cancelada", motivo_cancelamento: "Adiada").codigo
      exportar = ->(filtros) { get(transporte_relatorios_path(format: :xlsx), params: { tipo: "solicitacoes", inicio: "08/10/2026", fim: "08/10/2026" }.merge(filtros)) && textos_da_planilha(response.body) }

      expect([ exportar.call({}) & [ aprovada, cancelada ], exportar.call(status: "cancelada") & [ aprovada, cancelada ] ]).to eq([ [ aprovada, cancelada ], [ cancelada ] ])

      get transporte_relatorios_path
      botao = Nokogiri::HTML(response.body).at_css("button[title='Exportar Excel']")
      expect(botao.to_h.slice("form", "formaction", "formmethod")).to eq("form" => "filtros_do_relatorio", "formaction" => "/transporte/relatorios.xlsx", "formmethod" => "get")
    end

    it "sem datas, usa do começo do mês até hoje" do
      relatorio = Transporte::Relatorios::Consultar.call(tipo: "inexistente")

      expect(relatorio).to have_attributes(tipo: "solicitacoes", inicio: Date.new(2026, 10, 1), fim: Date.new(2026, 10, 8))
    end
  end
end
