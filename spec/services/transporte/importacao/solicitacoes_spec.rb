require "rails_helper"

RSpec.describe Transporte::Importacao::Solicitacoes do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tecnico) { create(:user, nome: "TEC TRANSPORTE").tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "tecnico") } }
  let(:unidade_antiga) { inserir_no_legado(:unidades, nome: "Núcleo de Informática", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "SEDE")) }
  let(:agora) { Time.zone.local(2026, 10, 5, 10, 0) }

  before do
    create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO", legacy_id: unidade_antiga)
    travel_to agora
  end

  def antiga(status, saida: agora - 1.year, tipo: 2, **outros)
    inserir_no_legado(:requisicao_transportes, { status: status, tipo: tipo, user_id: maria.id, unidade_id: unidade_antiga, motivo: "Reunião na SEAD", data_hora_ida: saida }.merge(outros)).tap do |id|
      pedido = (saida - 3.days).utc.to_fs(:db) # pedida três dias antes da saída
      ActiveRecord::Base.connection.execute("UPDATE requisicao_transportes SET created_at = '#{pedido}', updated_at = '#{pedido}' WHERE id = #{id}")
      inserir_no_legado(:passageiros, nome: "Maria Oliveira", cpf: "529.982.247-25", requisicao_transporte_id: id, user_id: maria.id)
      inserir_no_legado(:destinos, descricao: "SEAD", cep: "68900-073", numero: 96, requisicao_transporte_id: id, user_id: maria.id)
    end
  end

  def nova(id) = Transporte::Solicitacao.find_by!(legacy_id: id)

  it "a finalizada chega concluída, com o mesmo número, passageiro, destino ajustado e histórico" do
    tecnico
    id = antiga(6, data_hora_aprovada: agora - 1.year - 1.day, usuario_aprovou: "TEC TRANSPORTE", data_hora_finalizada: agora - 1.year + 2.hours, usuario_finalizou: "MOTORISTA ANTIGO")

    relatorio = described_class.call

    solicitacao = nova(id)
    expect(relatorio).to have_attributes(antigas: 1, importadas: 1, ignoradas: [], canceladas_por_data: 0, passageiros: 1, destinos: 1)
    expect(solicitacao).to have_attributes(id: id, codigo: format("TR-%06d", id), status: "concluida", tipo: "normal", modo: "so_deixar", fora_do_padrao: false, resumo: "Reunião na SEAD",
                                           solicitante: maria, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", aprovada_por: tecnico, concluida_em: agora - 1.year + 2.hours)
    expect(solicitacao.passageiros.sole).to have_attributes(nome: "MARIA OLIVEIRA", cpf: "52998224725")
    expect(solicitacao.destinos.sole).to have_attributes(nome: "SEAD", cep: "68900-073", numero: "96", logradouro: "NÃO INFORMADO", bairro: "NÃO INFORMADO", cidade: "NÃO INFORMADO", uf: "AP")
    expect(solicitacao.eventos.em_ordem.pluck(:tipo, :ator_nome)).to eq([ [ "aberta", "MARIA OLIVEIRA" ], [ "aprovada", "TEC TRANSPORTE" ], [ "concluida", "MOTORISTA ANTIGO" ] ])
  end

  it "negada vira cancelada com o motivo da negação; urgente vira normal fora do prazo; viagem mantém o retorno" do
    negada = antiga(4, motivo_negada: "Sem veículo.", data_hora_negada: agora - 1.year, usuario_negou: "TEC TRANSPORTE")
    urgente = antiga(5, tipo: 1)
    viagem = antiga(6, tipo: 3, data_hora_retorno: agora - 1.year + 2.days)

    described_class.call

    expect(nova(negada)).to have_attributes(status: "cancelada", motivo_cancelamento: "Negada pelo setor de transporte: Sem veículo.", cancelada_em: agora - 1.year)
    expect(nova(urgente)).to have_attributes(status: "cancelada", tipo: "normal", fora_do_padrao: true, motivo_cancelamento: "Cancelada no siscom antigo (o motivo não era registrado).")
    expect(nova(viagem)).to have_attributes(status: "concluida", tipo: "viagem", retorno_em: agora - 1.year + 2.days)
  end

  it "aguardando ou aprovada com saída há mais de um mês é cancelada com o motivo de data muito antiga; a recente fica como estava" do
    antiga_aprovada = antiga(2, saida: Time.zone.local(2025, 5, 20, 8, 0))
    antiga_aguardando = antiga(1, saida: agora - 40.days)
    recente = antiga(2, saida: agora - 10.days)
    futura = antiga(1, saida: agora + 3.days)

    relatorio = described_class.call

    expect(relatorio.canceladas_por_data).to eq(2)
    expect(nova(antiga_aprovada)).to have_attributes(
      status: "cancelada", cancelada_em: agora, cancelada_por: nil,
      motivo_cancelamento: 'Cancelada na migração do siscom antigo: data muito antiga (saída em 20/05/2025 08:00, estava como "aprovada" e nunca foi encerrada).'
    )
    expect(nova(antiga_aprovada).eventos.em_ordem.last).to have_attributes(tipo: "cancelada", ator_nome: "Migração do siscom antigo", ocorrido_em: agora)
    expect([ nova(antiga_aguardando), nova(recente), nova(futura) ].map(&:status)).to eq(%w[cancelada aprovada solicitada])
  end

  it "o serviço antigo (motorista sem conta, veículo sem cadastro novo) fica no histórico, sem afrouxar o banco" do
    id = antiga(6)
    motorista = inserir_no_legado(:motoristas, nome: "JOSE MOTORISTA", cpf: "1")
    inserir_no_legado(:servico_transportes, requisicao_transporte_id: id, motorista_id: motorista, veiculo_id: inserir_no_legado(:veiculos, placa: "QLM1234"), status: 0, km_inicial: 1000, km_final: 1042)

    relatorio = described_class.call

    expect(relatorio.servicos_no_historico).to eq(1)
    expect(nova(id).servicos).to be_empty
    expect(nova(id).eventos.find_by!(tipo: "servico_iniciado")).to have_attributes(
      ator_nome: "JOSE MOTORISTA", nota: "Serviço registrado no siscom antigo: motorista JOSE MOTORISTA, veículo QLM1234. Km 1000 a 1042 (42 km)."
    )
  end

  it "saída com o ano impossível usa a data do pedido, avisa no histórico e cai na regra da data antiga" do
    id = antiga(2)
    ActiveRecord::Base.connection.execute("UPDATE requisicao_transportes SET data_hora_ida = '20250-09-26 11:00:00' WHERE id = #{id}")

    described_class.call

    expect(nova(id)).to have_attributes(status: "cancelada", saida_em: agora - 1.year - 3.days)
    expect(nova(id).eventos.find_by!(tipo: "aberta").nota).to include("A data de saída gravada no siscom antigo era impossível (20250-09-26 11:00:00)")
  end

  it "motivo maior que o limite do resumo é encurtado, e o texto completo fica no histórico" do
    id = antiga(6, motivo: "Reunião " * 200)

    described_class.call

    expect(nova(id).resumo.length).to eq(1000)
    expect(nova(id)).to be_valid
    expect(nova(id).eventos.find_by!(tipo: "aberta").nota).to include("Motivo completo: #{('Reunião ' * 200).squish}")
  end

  it "pode rodar de novo sem duplicar, não avisa ninguém, e a próxima solicitação nova continua a numeração" do
    tecnico
    id = antiga(6)
    expect { described_class.call }.not_to change(Core::Notificacao, :count)

    relatorio = described_class.call
    seguinte = Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", resumo: "Nova", saida_em: 3.days.from_now, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email)

    expect(relatorio).to have_attributes(importadas: 0, ja_existiam: 1)
    expect([ Transporte::Solicitacao.where(legacy_id: id).count, Transporte::Passageiro.count, Transporte::Destino.count ]).to eq([ 1, 1, 1 ])
    expect(seguinte.id).to be > id
  end

  it "a solicitação migrada que ainda vale continua andando: a operação aprova e o solicitante cancela" do
    tecnico
    pendente = antiga(1, saida: agora + 3.days)
    aprovada = antiga(2, saida: agora + 2.days)
    described_class.call

    expect(Transporte::Solicitacoes::Aprovar.call(solicitacao: nova(pendente), ator: tecnico)).to be_sucesso
    expect(Transporte::Solicitacoes::Cancelar.call(solicitacao: nova(aprovada), ator: maria, motivo: "Não preciso mais.")).to be_sucesso
    expect([ nova(pendente), nova(aprovada) ].map(&:status)).to eq(%w[aprovada cancelada])
  end
end
