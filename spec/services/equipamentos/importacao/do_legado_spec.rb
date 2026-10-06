require "rails_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Equipamentos::Importacao::DoLegado do
  let(:rosineide) { create(:user, nome: "ROSINEIDE CAMPOS") }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tipo) { inserir_no_legado(:tipo_unidades, nome: "SEDE") }
  let(:nuinfo_antiga) { inserir_no_legado(:unidades, nome: "Núcleo de Informática", tipo_unidade_id: tipo) }
  let(:asjur_antiga) { inserir_no_legado(:unidades, nome: "Assessoria Jurídica", tipo_unidade_id: tipo) }
  let!(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO", legacy_id: nuinfo_antiga) }
  let!(:asjur) { create(:rh_unidade, nome: "Assessoria Jurídica", sigla: "ASJUR", legacy_id: asjur_antiga) }

  def equipamento(unidade: nuinfo_antiga, **outros)
    cadastro = { acao: "cadastro", data: "2025-12-05T14:58:40-03:00", usuario: "ROSINEIDE CAMPOS", usuario_id: rosineide.id, detalhes: "Equipamento cadastrado no sistema - Unidade: NUINFO" }
    inserir_no_legado(:equipamentos, { tipo: "individual", tipo_equipamento: "Monitor", marca: "dell", modelo: "p2419h", numero_patrimonio: "PAT#{SecureRandom.hex(4)}", outra_identificacao: "", status: 0,
                                       unidade_id: unidade, user_id: rosineide.id, codigo_kit: "20251205145840", identificacao_kit: "KIT I5", itens_kit: "[]",
                                       historico_movimentacoes: [ cadastro ].to_json }.merge(outros))
  end

  def movimentacao(status, itens, destino: asjur_antiga)
    inserir_no_legado(:movimentacao_equipamentos, unidade_origem_id: nuinfo_antiga, unidade_destino_id: destino, responsavel_id: maria.id, user_id: rosineide.id, status: status,
                                                  descricao: "Troca de sala", data_movimentacao: Time.zone.local(2025, 12, 10, 16, 0)).tap do |id|
      itens.each { |item, da_linha| inserir_no_legado(:item_movimentacoes, movimentacao_equipamento_id: id, equipamento_id: item, status: da_linha, recebido: da_linha == "recebido", data_recebimento: (Time.zone.local(2025, 12, 11, 9, 0) if da_linha == "recebido")) }
    end
  end

  def novo(id) = Equipamentos::Item.find_by!(legacy_id: id)

  it "o equipamento chega com o mesmo número, na unidade nova, com o histórico em linhas" do
    id = equipamento(numero_patrimonio: "pat001", numero_serial: "sn-1", garantia: 12, contrato: "007/2025")
    avulso = equipamento(codigo_kit: "", identificacao_kit: "")

    relatorio = described_class.call

    expect(novo(avulso)).to have_attributes(codigo_kit: nil, identificacao_kit: nil, no_kit?: false)

    expect(relatorio).to have_attributes(antigos: 2, importados: 2, ja_existiam: 0, ignorados: [], eventos: 2)
    expect(novo(id)).to have_attributes(id: id, marca: "DELL", modelo: "P2419H", numero_patrimonio: "PAT001", numero_serial: "SN-1", outra_identificacao: nil, garantia: 12, contrato: "007/2025",
                                        status: "ativo", situacao: "disponivel", rh_unidade_id: nuinfo.id, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", cadastrado_por: rosineide,
                                        codigo_kit: "20251205145840", identificacao_kit: "KIT I5")
    expect(novo(id).eventos.sole).to have_attributes(tipo: "cadastrado", ator: rosineide, ator_nome: "ROSINEIDE CAMPOS", ocorrido_em: Time.zone.parse("2025-12-05T14:58:40-03:00"))
  end

  it "é idempotente: rodar de novo não duplica equipamento, histórico nem movimentação" do
    movimentacao("em_andamento", { equipamento => "pendente" })

    described_class.call
    relatorio = described_class.call

    expect(relatorio).to have_attributes(importados: 0, ja_existiam: 1, movimentacoes: 0, movimentacoes_ja_existiam: 1)
    expect([ Equipamentos::Item.count, Equipamentos::Movimentacao.count, Equipamentos::ItemMovimentacao.count, Equipamentos::Evento.count ]).to eq([ 1, 1, 1, 2 ])
  end

  it "a movimentação pendente chega em andamento: o equipamento fica em movimentação e quem recebe dá o recebido" do
    item = equipamento
    id = movimentacao("em_andamento", { item => "pendente" })

    relatorio = described_class.call

    envio = Equipamentos::Movimentacao.find_by!(legacy_id: id)
    expect(relatorio).to have_attributes(movimentacoes_antigas: 1, movimentacoes: 1, linhas: 1, em_movimentacao: 1)
    expect(envio).to have_attributes(id: id, codigo: format("MV-%06d", id), tipo: "movimentacao", status: "em_andamento", origem_nome: "NUINFO - NÚCLEO DE INFORMÁTICA",
                                     destino_nome: "ASJUR - ASSESSORIA JURÍDICA", responsavel: maria, criada_por: rosineide, descricao: "Troca de sala", created_at: Time.zone.local(2025, 12, 10, 16, 0))
    expect(Equipamentos::Envios::Operar.call(envio: envio, acao: "receber_item", ator: maria)).to be_sucesso
    expect(novo(item)).to have_attributes(situacao: "disponivel", rh_unidade_id: asjur.id)
  end

  it "recebida e cancelada chegam encerradas; a inicial (origem = destino) não vem" do
    recebido = equipamento(unidade: asjur_antiga)
    cancelado = equipamento
    concluida = movimentacao("concluida", { recebido => "recebido" })
    cancelada = movimentacao("cancelada", { cancelado => "cancelada" })
    movimentacao("concluida", { cancelado => "pendente" }, destino: nuinfo_antiga)

    described_class.call

    expect(Equipamentos::Movimentacao.order(:id).pluck(:legacy_id, :status)).to eq([ [ concluida, "concluida" ], [ cancelada, "cancelada" ] ])
    expect(Equipamentos::ItemMovimentacao.order(:id).map { |linha| [ linha.status, linha.recebido_por, linha.cancelado_por ] }).to eq([ [ "recebido", maria, nil ], [ "cancelado", nil, rosineide ] ])
    expect([ novo(recebido), novo(cancelado) ].map(&:situacao)).to eq(%w[disponivel disponivel])
    expect(novo(cancelado).eventos.em_ordem.pluck(:tipo)).to eq(%w[cadastrado movimentacao_criada movimentacao_cancelada])
  end

  it "ajusta o switch sem MAC (sem afrouxar a regra), ignora o que não tem unidade nova e dá a permissão de administrador só a quem foi combinado" do
    josue = create(:user, email: described_class::ADMINISTRADOR_INICIAL)
    switch = equipamento(tipo_equipamento: "Switch", marca: "ARUBA", modelo: "JL808A")
    orfao = equipamento(unidade: inserir_no_legado(:unidades, nome: "Unidade extinta", tipo_unidade_id: tipo))

    relatorio = described_class.call

    expect(novo(switch)).to have_attributes(mac: "NÃO INFORMADO (#{switch})", ativo_de_rede: "NÃO INFORMADO")
    expect(novo(switch).eventos.em_ordem.last.nota).to include("MAC e ativo de rede não informado(s) no siscom antigo")
    expect(relatorio.ignorados).to contain_exactly(a_string_matching(/equipamento #{orfao}: a unidade antiga \d+ não existe no RH novo/))
    expect(relatorio).to have_attributes(ajustados: [ a_string_including("equipamento #{switch} (switch)") ], administrador: josue.email)
    expect(Core::Concessao.ativo.where(modulo: "equipamentos").pluck(:user_id, :papel)).to eq([ [ josue.id, "admin" ] ])
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
