require "rails_helper"

RSpec.describe Transporte::AlertasJob do
  include ActiveSupport::Testing::TimeHelpers

  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let!(:tecnico) { com_papel("tecnico", "TECNICO") }

  def solicitacao(**atributos)
    Transporte::Solicitacao.create!({ tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Reunião", saida_em: 20.minutes.from_now, solicitante: maria,
                                      solicitante_nome: maria.nome, solicitante_email: maria.email }.merge(atributos))
  end

  before { travel_to Time.zone.local(2026, 10, 8, 8, 40) }

  it "lembra a saída uma única vez, para o solicitante e a operação, só das aprovadas dentro do prazo" do
    proxima = solicitacao
    solicitacao(saida_em: 2.hours.from_now)
    solicitacao(status: "solicitada")

    2.times { described_class.perform_now }

    expect(maria.notificacoes.pluck(:titulo)).to eq([ "Seu transporte sai às 09:00" ])
    expect(tecnico.notificacoes.pluck(:titulo)).to eq([ "Saída às 09:00" ])
    expect(proxima.reload.lembrete_enviado_em).to be_present
  end

  it "avisa a operação da busca atrasada e repete depois do intervalo, enquanto ninguém sai para buscar" do
    atrasada = solicitacao(modo: "buscar_depois", busca_horas: 1, status: "busca", busca_prevista_em: 10.minutes.ago)
    solicitacao(modo: "buscar_depois", busca_horas: 1, status: "busca", busca_prevista_em: 1.hour.from_now)

    described_class.perform_now
    travel 5.minutes
    described_class.perform_now
    expect(tecnico.notificacoes.where(titulo: "Busca em atraso").count).to eq(1)

    travel 6.minutes
    described_class.perform_now
    expect(tecnico.notificacoes.where(titulo: "Busca em atraso").count).to eq(2)

    motorista = com_papel("motorista", "JOAO")
    atrasada.servicos.create!(trecho: "busca", motorista: motorista, motorista_nome: "JOAO", veiculo: create(:transporte_veiculo), placa: "QLM1A23", odometro_inicial: 1, iniciado_em: Time.current)
    travel 11.minutes
    described_class.perform_now
    expect(tecnico.notificacoes.where(titulo: "Busca em atraso").count).to eq(2)
  end

  it "está agendado para rodar a cada minuto" do
    agenda = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)

    expect(agenda.dig("production", "transporte_alertas")).to eq("class" => "Transporte::AlertasJob", "schedule" => "every minute")
    expect(agenda.dig("development", "transporte_alertas")).to be_present
  end
end
