require "rails_helper"

RSpec.describe "Transporte: serviços do motorista" do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:joao) { com_papel("motorista", "JOAO MOTORISTA") }
  let!(:hilux) { create(:transporte_veiculo, placa: "QLM1A23", odometro_atual: 12_000) }
  let!(:solicitacao) do
    Transporte::Solicitacao.create!(tipo: "normal", modo: "buscar_depois", busca_horas: 3, status: "aprovada", resumo: "Reunião na SEAD", saida_em: 1.hour.from_now,
                                    solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email)
  end

  it "quem não é motorista não entra" do
    sign_in maria

    respostas = [ -> { get transporte_servicos_path }, -> { get transporte_servico_path(solicitacao) },
                  -> { patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 12_050 } } ].map { |r| r.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com motorista" do
    before { sign_in joao }

    it "vê o que está para sair e procura um veículo livre pela placa" do
      get transporte_servicos_path
      expect(response.body).to include("Meus serviços", "Para sair", solicitacao.codigo, "Reunião na SEAD")

      get veiculos_transporte_servicos_path, params: { q: "qlm" }
      expect(response.parsed_body["opcoes"]).to eq([ { "valor" => hilux.id, "rotulo" => "QLM1A23 · TOYOTA HILUX", "subtitulo" => "Odômetro: 12000 km" } ])
    end

    it "mostra o painel de saída e recusa odômetro menor que o do veículo" do
      get inicio_transporte_servico_path(solicitacao)
      expect(response.body).to include("Iniciar serviço #{solicitacao.codigo}", "Veículo *", "Odômetro inicial (km) *")

      patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 11_000 }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("não pode ser menor que o atual do veículo")
    end

    it "inicia, chega ao destino e depois faz a busca: a solicitação termina concluída" do
      patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 12_050 }
      ver_no_painel transporte_servico_path(solicitacao)
      expect(response.body).to include("Em serviço", "JOAO MOTORISTA", "QLM1A23", "em andamento", "Serviço iniciado")
      get transporte_servicos_path, params: { status: "andamento" }
      expect(response.body).to include("Finalizar trecho", "Registrar observação")

      patch finalizar_transporte_servico_path(solicitacao), params: { odometro: 12_080 }
      get transporte_servicos_path, params: { status: "buscas" }
      expect(response.body).to include(solicitacao.codigo, "Aguardando busca", "Buscar até")

      patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 12_100 }
      patch finalizar_transporte_servico_path(solicitacao), params: { odometro: 12_130 }
      expect(solicitacao.reload).to have_attributes(status: "concluida")
      get transporte_servicos_path, params: { status: "feitos" }
      expect(response.body).to include(solicitacao.codigo)
    end

    it "oferece levar junto outras solicitações aprovadas e mostra o serviço compartilhado" do
      pedro = com_papel("solicitante", "PEDRO SANTOS")
      outra = Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Entrega de documentos", saida_em: 2.hours.from_now,
                                              solicitante: pedro, solicitante_nome: pedro.nome, solicitante_email: pedro.email)

      get inicio_transporte_servico_path(solicitacao)
      expect(response.body).to include("Levar junto na mesma viagem", outra.codigo, "PEDRO SANTOS")

      patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 12_050, outras_ids: [ outra.id ] }
      ver_no_painel transporte_servico_path(outra)
      expect(response.body).to include("Serviço compartilhado com #{solicitacao.codigo}", "Em serviço")
    end

    it "registra observação com anexo na solicitação que atendeu" do
      get new_transporte_solicitacao_observacao_path(solicitacao)
      expect(response).to have_http_status(:forbidden)

      patch iniciar_transporte_servico_path(solicitacao), params: { veiculo_id: hilux.id, odometro: 12_050 }
      post transporte_solicitacao_observacoes_path(solicitacao), params: { corpo: "Trânsito parado na FAB" }

      expect(response).to redirect_to(transporte_servicos_path)
      ver_no_painel transporte_servico_path(solicitacao)
      expect(response.body).to include("Observações (1)", "Trânsito parado na FAB", "JOAO MOTORISTA (Motorista)")
    end
  end

  it "ao finalizar, quem fecha pode deixar uma observação com anexo (anexo só junto com a observação)" do
    Transporte::Servicos::Iniciar.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050)
    foto = Rack::Test::UploadedFile.new(StringIO.new("foto"), "image/jpeg", original_filename: "pneu.jpg")
    sign_in joao

    patch finalizar_transporte_servico_path(solicitacao), params: { odometro: 12_080, anexos: [ foto ] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Para enviar anexos, escreva a observação.")

    patch finalizar_transporte_servico_path(solicitacao), params: { odometro: 12_080, observacao: "Pneu furou", anexos: [ foto ] }
    expect(solicitacao.reload).to be_busca
    expect(solicitacao.observacoes.sole).to have_attributes(corpo: "Pneu furou", papel: "motorista", autor: joao)
    expect(solicitacao.observacoes.sole.anexos.sole.filename.to_s).to eq("pneu.jpg")
  end

  it "Veículos agora mostra os livres e os que estão em serviço, com motorista e solicitação" do
    create(:transporte_veiculo, placa: "ABC1D23", marca: "FIAT", modelo: "STRADA")
    Transporte::Servicos::Iniciar.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050)

    sign_in com_papel("tecnico", "TECNICO")
    get transporte_veiculos_agora_path

    html = Nokogiri::HTML(response.body)
    expect(html.css("#veiculos_livres li").map { |item| item.text.squish }).to eq([ "ABC1D23 · FIAT STRADA BRANCA · 4 lugar(es) · 12.000 km" ])
    expect(html.at_css("#veiculos_em_servico").text.squish).to include("QLM1A23 · TOYOTA HILUX", "JOAO MOTORISTA", "#{solicitacao.codigo} · MARIA OLIVEIRA")
  end

  it "Veículos agora é só da operação" do
    sign_in joao
    get transporte_veiculos_agora_path
    expect(response).to have_http_status(:forbidden)
  end

  it "o solicitante vê o serviço, mas não as observações; a operação vê as duas coisas" do
    Transporte::Servicos::Iniciar.call(solicitacao: solicitacao, ator: joao, veiculo_id: hilux.id, odometro: 12_050)
    Transporte::Solicitacoes::Observar.call(solicitacao: solicitacao, ator: joao, corpo: "Trânsito parado na FAB")

    sign_in maria
    ver_no_painel transporte_solicitacao_path(solicitacao)
    expect(response.body).to include("Serviço", "JOAO MOTORISTA", "QLM1A23", "Histórico")
    expect(response.body).not_to include("Trânsito parado na FAB")

    sign_in com_papel("tecnico", "TECNICO")
    ver_no_painel transporte_operacao_path(solicitacao)
    expect(response.body).to include("Trânsito parado na FAB", "Observações (1)")
    expect(response.body).not_to include("Registrar observação") # as ações ficam na linha da lista
  end
end
