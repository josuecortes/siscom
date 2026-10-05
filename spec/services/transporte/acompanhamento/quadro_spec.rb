require "rails_helper"

RSpec.describe Transporte::Acompanhamento::Quadro do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:agora) { Time.zone.local(2026, 10, 5, 10, 0) }

  before { travel_to agora }

  def solicitacao(status, saida, **outros)
    Transporte::Solicitacao.new({ tipo: "normal", modo: "so_deixar", status: status, resumo: "Reunião", saida_em: saida, solicitante: maria,
                                  solicitante_nome: maria.nome, solicitante_email: maria.email }.merge(outros)).tap { |s| s.save!(validate: false) }
  end

  def em_servico(inicio, **outros)
    solicitacao("em_servico", inicio, **outros).tap do |s|
      s.servicos.create!(trecho: "ida", motorista: maria, motorista_nome: "JOAO MOTORISTA", veiculo: create(:transporte_veiculo), placa: "QLM1A23",
                         odometro_inicial: 1, iniciado_em: inicio)
    end
  end

  def coluna(chave) = described_class.new.colunas.find { |item| item.chave == chave }.itens.map { |item| [ item.nivel, item.aviso ] }

  it "pedido sem aprovação: quanto mais perto da saída, mais grave; o mais urgente vem primeiro" do
    solicitacao("solicitada", agora + 3.days)
    solicitacao("solicitada", agora + 20.hours)
    solicitacao("solicitada", agora + 90.minutes)
    solicitacao("solicitada", agora - 40.minutes)
    solicitacao("reagendada", agora + 30.minutes)

    expect(coluna("aprovacao")).to eq([ [ "critico", "A saída era há 40 min e está sem aprovação" ],
                                        [ "urgente", "Sai em 30 min e está sem resposta do solicitante ao reagendamento" ],
                                        [ "urgente", "Sai em 1 h 30 min e está sem aprovação" ],
                                        [ "atencao", "Sai em 20 h, sem aprovação" ], [ "normal", nil ] ])
  end

  it "saída aprovada: atrasada (mesmo de dias atrás), falta pouco, atenção e no prazo; depois de amanhã não aparece" do
    [ agora - 2.days, agora - 20.minutes, agora + 45.minutes, agora + 100.minutes, agora + 5.hours, agora + 3.days ].each { |saida| solicitacao("aprovada", saida) }

    expect(coluna("saidas")).to eq([ [ "critico", "Devia ter saído há 2 dias: nenhum motorista iniciou" ], [ "critico", "Devia ter saído há 20 min: nenhum motorista iniciou" ],
                                     [ "urgente", "Sai em 45 min" ], [ "atencao", "Sai em 1 h 40 min" ], [ "normal", nil ] ])
  end

  it "em andamento: avisa quando passa do previsto (com a espera) e quando o motorista parece ter esquecido a chegada" do
    em_servico(agora - 20.minutes)
    em_servico(agora - 3.hours)
    em_servico(agora - 3.hours, modo: "esperar_no_local", espera_horas: 2)
    em_servico(agora - 6.hours)
    em_servico(agora - 4.days, tipo: "viagem", retorno_em: agora + 1.day)

    expect(coluna("andamento")).to eq([ [ "critico", "Sem chegada registrada 4 h depois do previsto: confirmar com o motorista" ],
                                        [ "atencao", "Passou 1 h do tempo previsto" ], [ "normal", "Na rua há 4 dias" ],
                                        [ "normal", "Na rua há 3 h" ], [ "normal", "Na rua há 20 min" ] ])
  end

  it "aguardando busca: vencida, perto da hora e sem motorista a caminho; o resumo conta o quadro todo" do
    [ agora - 5.hours, agora + 20.minutes, agora + 50.minutes, agora + 2.hours ].each do |prevista|
      solicitacao("busca", prevista - 4.hours, modo: "buscar_depois", busca_horas: 3, busca_prevista_em: prevista)
    end
    a_caminho = solicitacao("busca", agora - 5.hours, modo: "buscar_depois", busca_horas: 3, busca_prevista_em: agora - 10.minutes)
    a_caminho.servicos.create!(trecho: "busca", motorista: maria, motorista_nome: "JOAO MOTORISTA", veiculo: create(:transporte_veiculo), placa: "QLM1A23",
                               odometro_inicial: 1, iniciado_em: agora - 5.minutes)

    expect(coluna("buscas")).to eq([ [ "critico", "Esperando a busca há 5 h: ninguém saiu para buscar" ], [ "urgente", "Buscar em 20 min" ],
                                     [ "atencao", "Buscar em 50 min" ], [ "normal", nil ] ])
    expect(described_class.new.contagem).to eq("critico" => 1, "urgente" => 1, "atencao" => 1, "normal" => 2)
  end
end
