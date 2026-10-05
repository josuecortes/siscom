require "rails_helper"

RSpec.describe Ti::Acompanhamento::Quadro do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { create(:user, nome: "JOAO TECNICO") }
  let(:solicitacao) { create(:ti_problema, nome: "Sem internet") }
  let(:agora) { Time.zone.local(2026, 10, 5, 10, 0) }

  before { travel_to agora }

  def chamado(status, ha:, prioridade: "normal", **outros)
    Ti::Chamado.create!({ problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, status: status,
                          prioridade: prioridade, aberto_em: agora - ha }.merge(outros)).tap { |c| c.update_columns(updated_at: agora - ha) }
  end

  def coluna(chave) = described_class.new.colunas.find { |item| item.chave == chave }.itens.map { |item| [ item.nivel, item.aviso ] }

  it "sem responsável: o limite depende da prioridade, e o mais urgente vem primeiro" do
    chamado("aberto", ha: 1.hour)
    chamado("aberto", ha: 3.hours)
    chamado("aberto", ha: 1.hour, prioridade: "critica")
    chamado("aguardando_tecnico", ha: 2.days, prioridade: "alta", triado_em: agora - 150.minutes)

    expect(coluna("espera")).to eq([ [ "critico", "Sem responsável há 1 h" ], [ "urgente", "Triado, sem técnico há 2 h 30 min" ],
                                     [ "atencao", "Sem responsável há 3 h" ], [ "normal", "Sem responsável há 1 h" ] ])
  end

  it "mostra a prioridade, a solicitação e a unidade em cada cartão" do
    chamado("aberto", ha: 5.minutes, prioridade: "urgente", unidade_nome: "NUINFO")

    item = described_class.new.colunas.first.itens.sole
    expect(item).to have_attributes(nome: "MARIA OLIVEIRA", detalhe: "URGENTE · SEM INTERNET · NUINFO", horario: agora - 5.minutes, nivel: "normal")
  end

  it "em triagem e em atendimento: diz com quem está e há quanto tempo sem novidade" do
    chamado("em_triagem", ha: 5.hours, triador: joao, triado_em: agora - 5.hours)
    chamado("em_atendimento", ha: 2.hours, responsavel: joao)
    chamado("em_atendimento", ha: 2.days, responsavel: joao)
    chamado("em_atendimento", ha: 5.hours, responsavel: joao, prioridade: "critica")

    expect(coluna("triagem")).to eq([ [ "urgente", "Em triagem com Joao há 5 h" ] ])
    expect(coluna("atendimento")).to eq([ [ "critico", "Com Joao há 5 h, sem novidade" ], [ "urgente", "Com Joao há 2 dias, sem novidade" ],
                                          [ "normal", "Com Joao há 2 h, sem novidade" ] ])
  end

  it "parados: esperando o solicitante ou impedidos, por dias; encerrados não aparecem" do
    chamado("aguardando_solicitante", ha: 5.hours)
    chamado("impedido", ha: 4.days, responsavel: joao)
    chamado("concluido", ha: 4.days)
    chamado("cancelado", ha: 4.days)

    expect(coluna("parados")).to eq([ [ "critico", "Impedido há 4 dias" ], [ "normal", "Esperando o solicitante há 5 h" ] ])
    expect(described_class.new.contagem).to eq("critico" => 1, "normal" => 1)
  end
end
