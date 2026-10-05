require "rails_helper"

# Iniciar e finalizar os trechos do serviço, com a regra do odômetro, e as observações.
RSpec.describe Transporte::Servicos::Iniciar do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:joao) { com_papel("motorista", "JOAO MOTORISTA") }
  let(:hilux) { create(:transporte_veiculo, placa: "QLM1A23", odometro_atual: 12_000) }
  let(:solicitacao) { criar_solicitacao }

  def criar_solicitacao(modo: "so_deixar", **outros)
    Transporte::Solicitacao.create!({ tipo: "normal", modo: modo, status: "aprovada", resumo: "Reunião", saida_em: 1.hour.from_now, solicitante: maria,
                                      solicitante_nome: maria.nome, solicitante_email: maria.email, busca_horas: (3 if modo == "buscar_depois") }.merge(outros))
  end

  def iniciar(alvo = solicitacao, ator: joao, veiculo: hilux, odometro: 12_050) = Transporte::Servicos::Iniciar.call(solicitacao: alvo.reload, ator: ator, veiculo_id: veiculo.id, odometro: odometro)
  def finalizar(alvo = solicitacao, ator: joao, odometro: 12_080) = Transporte::Servicos::Finalizar.call(solicitacao: alvo.reload, ator: ator, odometro: odometro)

  it "o motorista inicia a ida: a solicitação entra em serviço, o veículo fica ocupado e o solicitante é avisado" do
    resultado = iniciar

    expect(resultado).to be_sucesso
    expect(solicitacao.reload).to have_attributes(status: "em_servico")
    expect(solicitacao.servico_aberto).to have_attributes(trecho: "ida", motorista: joao, placa: "QLM1A23", odometro_inicial: 12_050)
    expect(hilux.reload.odometro_atual).to eq(12_050)
    expect(maria.notificacoes.last).to have_attributes(titulo: "Seu transporte saiu")
  end

  it "não aceita odômetro menor que o atual do veículo, veículo em uso, nem quem não é motorista" do
    expect(iniciar(odometro: 11_999).mensagem_de_erro).to include("não pode ser menor que o atual do veículo (12000 km)")
    expect(iniciar(odometro: "doze mil")).to be_falha
    expect(iniciar(ator: maria)).to be_falha

    iniciar
    outra = criar_solicitacao
    expect(iniciar(outra).mensagem_de_erro).to include("QLM1A23 já está em serviço")
    expect(iniciar.mensagem_de_erro).to include("sem serviço em andamento")
  end

  describe "saída em grupo" do
    let(:outra) do
      pedro = com_papel("solicitante", "PEDRO SANTOS")
      criar_solicitacao(solicitante: pedro, solicitante_nome: pedro.nome, solicitante_email: pedro.email)
    end

    it "leva várias solicitações no mesmo veículo e avisa todos de que o serviço é compartilhado" do
      tecnico = com_papel("tecnico", "TECNICO")

      resultado = described_class.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050, outras_ids: [ outra.id ])

      expect(resultado).to be_sucesso
      expect([ solicitacao.reload.status, outra.reload.status ]).to eq(%w[em_servico em_servico])
      expect(solicitacao.servico_aberto.companheiros.map(&:solicitacao)).to eq([ outra ])
      expect(maria.notificacoes.last).to have_attributes(titulo: "Seu transporte saiu (serviço compartilhado)", mensagem: include("leva também #{outra.codigo} (PEDRO SANTOS)"))
      expect([ outra.solicitante.notificacoes.last.titulo, tecnico.notificacoes.last.titulo ]).to eq([ "Seu transporte saiu (serviço compartilhado)", "Saída em grupo" ])
    end

    it "cada solicitação é finalizada no seu destino; o veículo só fica livre quando todas terminam" do
      described_class.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050, outras_ids: [ outra.id ])

      finalizar(solicitacao, odometro: 12_060)
      terceira = criar_solicitacao
      expect(iniciar(terceira, odometro: 12_070).mensagem_de_erro).to include("já está em serviço")

      finalizar(outra, odometro: 12_075)
      expect([ solicitacao.reload.status, outra.reload.status, hilux.reload.odometro_atual ]).to eq([ "concluida", "concluida", 12_075 ])
      expect(iniciar(terceira, odometro: 12_080)).to be_sucesso
    end

    it "não mistura etapas diferentes nem solicitação que já está em serviço" do
      outra.update!(status: "solicitada")

      resultado = described_class.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050, outras_ids: [ outra.id ])

      expect(resultado.mensagem_de_erro).to include("Para sair em grupo")
      expect(solicitacao.reload.status).to eq("aprovada")
    end
  end

  it "só inicia solicitação aprovada ou aguardando busca" do
    solicitacao.update!(status: "solicitada")

    expect(iniciar).to be_falha
  end

  describe Transporte::Servicos::Finalizar do
    it "só deixar: fecha o trecho, atualiza o odômetro do veículo e conclui" do
      iniciar

      expect(finalizar(odometro: 12_049).mensagem_de_erro).to include("não pode ser menor que o inicial (12050 km)")
      expect(finalizar).to be_sucesso
      expect(solicitacao.reload).to have_attributes(status: "concluida", concluida_em: be_present, servico_aberto: nil)
      expect(solicitacao.servicos.sole).to have_attributes(odometro_final: 12_080, km_rodados: 30)
      expect(hilux.reload.odometro_atual).to eq(12_080)
    end

    it "buscar depois: a ida deixa aguardando busca com a hora prevista; outro motorista busca e conclui" do
      tecnico = com_papel("tecnico", "TECNICO")
      pedro = com_papel("motorista", "PEDRO MOTORISTA")
      busca = criar_solicitacao(modo: "buscar_depois")

      iniciar(busca)
      finalizar(busca)
      expect(busca.reload).to have_attributes(status: "busca", busca_prevista_em: be_within(1.minute).of(3.hours.from_now))
      expect(tecnico.notificacoes.last.titulo).to eq("Solicitação aguardando busca")

      iniciar(busca, ator: pedro, odometro: 12_100)
      expect(busca.reload).to have_attributes(status: "busca", servico_aberto: have_attributes(trecho: "busca", motorista: pedro))
      finalizar(busca, ator: pedro, odometro: 12_130)
      expect(busca.reload).to have_attributes(status: "concluida", busca_prevista_em: nil)
      expect(busca.servicos.em_ordem.pluck(:trecho, :motorista_nome)).to eq([ [ "ida", "JOAO MOTORISTA" ], [ "busca", "PEDRO MOTORISTA" ] ])
    end

    it "outro motorista não fecha o trecho; a operação sim" do
      iniciar

      expect(finalizar(ator: com_papel("motorista", "PEDRO"))).to be_falha
      expect(finalizar(ator: com_papel("tecnico", "TECNICO"))).to be_sucesso
    end
  end

  describe Transporte::Solicitacoes::Observar do
    it "a operação observa em qualquer solicitação; o motorista só nas que atendeu; o solicitante nunca" do
      tecnico = com_papel("tecnico", "TECNICO")
      foto = Rack::Test::UploadedFile.new(StringIO.new("img"), "image/png", original_filename: "pneu.png")

      expect(described_class.call(solicitacao: solicitacao, ator: joao, corpo: "Pneu furado")).to be_falha
      expect(described_class.call(solicitacao: solicitacao, ator: maria, corpo: "Oi")).to be_falha
      expect(described_class.call(solicitacao: solicitacao, ator: tecnico, corpo: "Levar ofício").objeto).to have_attributes(papel: "tecnico", autor_nome: "TECNICO")

      iniciar
      observacao = described_class.call(solicitacao: solicitacao, ator: joao, corpo: " Pneu furado na volta ", anexos: [ foto ]).objeto
      expect(observacao).to have_attributes(papel: "motorista", corpo: "Pneu furado na volta")
      expect(observacao.anexos.sole.filename.to_s).to eq("pneu.png")
    end
  end
end
