require "rails_helper"

RSpec.describe Transporte::Solicitacoes::Abrir do
  include ActiveSupport::Testing::TimeHelpers

  def com_papel(papel, nome = nil) = create(:user, **{ nome: nome }.compact).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:tecnico) { com_papel("tecnico", "TECNICO DO TRANSPORTE") }
  let(:passageiros) { { "0" => { cpf: "529.982.247-25", nome: "Maria Oliveira" }, "1" => { cpf: "", nome: "" } } }
  let(:destinos) do
    [ { nome: "Palácio do Setentrião", cep: "68900073", logradouro: "Avenida FAB", numero: "96", bairro: "Central", cidade: "Macapá", uf: "ap",
        latitude: "0.034934", longitude: "-51.069395" } ]
  end
  let(:dados) { { tipo: "normal", modo: "so_deixar", resumo: "Reunião na SEAD", saida_em: "08/10/2026 09:00", passageiros: passageiros, destinos: destinos } }

  def abrir(user = maria, **outros) = described_class.call(user: user, atributos: dados.merge(outros.except(:aberto_por, :fora_do_padrao)), **outros.slice(:aberto_por, :fora_do_padrao))
  def erros(resultado) = resultado.objeto.errors.full_messages

  before do
    Rh::Tabelas.garantir_padroes
    travel_to Time.zone.local(2026, 10, 5, 8, 0)
  end

  it "abre com código, retrato do solicitante, passageiros e destinos, e avisa quem aprova" do
    tecnico

    resultado = abrir

    solicitacao = resultado.objeto
    expect(solicitacao).to have_attributes(codigo: format("TR-%06d", solicitacao.id), status: "solicitada", tipo: "normal", modo: "so_deixar",
                                           solicitante_nome: "MARIA OLIVEIRA", saida_em: Time.zone.local(2026, 10, 8, 9, 0), fora_do_padrao: false)
    expect(solicitacao.passageiros.sole).to have_attributes(cpf: "52998224725", nome: "MARIA OLIVEIRA")
    expect(solicitacao.destinos.sole).to have_attributes(cep: "68900-073", uf: "AP", latitude: 0.034934, endereco: "Avenida FAB, 96 - Central, Macapá/AP")
    expect(tecnico.notificacoes.sole.titulo).to eq("Nova solicitação de transporte")
    expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "transporte", evento: "solicitacao.aberta")
  end

  it "quem não tem a permissão de solicitante não abre" do
    resultado = abrir(create(:user))

    expect(resultado).to be_falha
    expect(Transporte::Solicitacao.count).to eq(0)
  end

  it "só aceita a saída dentro da janela de antecedência da configuração" do
    expect(erros(abrir(saida_em: "06/10/2026 09:00")).join).to include("está fora do prazo para pedir: deve ficar entre 07/10/2026 08:00 e 09/10/2026 12:00")
    expect(erros(abrir(saida_em: "20/10/2026 09:00")).join).to include("fora do prazo")
    expect(erros(abrir(saida_em: "amanhã cedo")).join).to include("deve ser uma data e hora válidas")

    Transporte::Configuracao.atual.update!(normal_antecedencia_min_horas: 24)
    expect(abrir(saida_em: "06/10/2026 09:00")).to be_sucesso
  end

  it "o modo de serviço pede as horas dentro da faixa configurada" do
    expect(erros(abrir(modo: "esperar_no_local")).join).to include("deve ser informado em horas")
    expect(erros(abrir(modo: "esperar_no_local", espera_horas: "5")).join).to include("deve ficar entre 1 e 2 hora(s)")
    expect(abrir(modo: "esperar_no_local", espera_horas: "2").objeto).to have_attributes(espera_horas: 2, busca_horas: nil)
    expect(abrir(modo: "buscar_depois", busca_horas: "6").objeto).to have_attributes(busca_horas: 6)
  end

  it "viagem exige retorno depois da saída e o documento" do
    documento = Rack::Test::UploadedFile.new(StringIO.new("%PDF"), "application/pdf", original_filename: "oficio.pdf")

    expect(erros(abrir(tipo: "viagem")).join).to include("deve ser anexado para viagem")
    expect(erros(abrir(tipo: "viagem", retorno_em: "08/10/2026 08:00", documento_da_viagem: documento)).join).to include("deve ser depois da saída")

    solicitacao = abrir(tipo: "viagem", retorno_em: "09/10/2026 18:00", documento_da_viagem: documento).objeto
    expect(solicitacao).to have_attributes(tipo: "viagem", retorno_em: Time.zone.local(2026, 10, 9, 18, 0))
    expect(solicitacao.documento_da_viagem.filename.to_s).to eq("oficio.pdf")
  end

  it "exige pelo menos um passageiro (com CPF válido, sem repetir) e um destino completo" do
    sem_nada = abrir(passageiros: {}, destinos: [])
    expect(erros(sem_nada)).to include(a_string_including("deve ter pelo menos um")).twice

    ruim = abrir(passageiros: [ { cpf: "111.111.111-11", nome: "Fulano" } ], destinos: [ destinos.first.merge(numero: "", uf: "Amapá") ])
    expect(ruim).to be_falha
    expect(ruim.objeto.passageiros.first.errors[:cpf]).to be_present
    expect(ruim.objeto.destinos.first.errors.attribute_names).to include(:numero, :uf)

    repetido = abrir(passageiros: [ passageiros["0"], passageiros["0"] ])
    expect(erros(repetido).join).to include("não pode repetir o mesmo CPF")
  end

  it "com duas lotações exige escolher; com uma, guarda a unidade" do
    pessoa = create(:rh_pessoa, user: maria, email: maria.email, nome: maria.nome)
    nuinfo = create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
    primeira = create(:rh_lotacao, pessoa: pessoa, unidade: nuinfo, funcao: create(:rh_funcao))
    expect(abrir.objeto).to have_attributes(rh_unidade_id: nuinfo.id, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA")

    segunda = create(:rh_lotacao, pessoa: pessoa, unidade: create(:rh_unidade, sigla: "EEA", nome: "Escola A"), funcao: primeira.funcao)
    expect(erros(abrir).join).to include("deve ser escolhida")
    expect(abrir(lotacao_id: segunda.id).objeto.unidade_nome).to eq("EEA - ESCOLA A")
  end

  describe "pela operação" do
    it "o técnico abre em nome de outra pessoa, inclusive fora do prazo" do
      resultado = abrir(maria, aberto_por: tecnico, fora_do_padrao: true, saida_em: "05/10/2026 14:00", modo: "esperar_no_local", espera_horas: "8")

      expect(resultado.objeto).to have_attributes(solicitante: maria, aberto_por: tecnico, fora_do_padrao: true, espera_horas: 8)
      expect(maria.notificacoes.sole.titulo).to eq("Solicitação de transporte aberta em seu nome")
    end

    it "o solicitante não usa o fora do prazo, e ninguém abre no passado" do
      expect(abrir(maria, fora_do_padrao: true, saida_em: "05/10/2026 14:00")).to be_falha
      expect(abrir(maria, aberto_por: maria, fora_do_padrao: true, saida_em: "05/10/2026 14:00")).to be_falha
      expect(erros(abrir(maria, aberto_por: tecnico, fora_do_padrao: true, saida_em: "04/10/2026 14:00")).join).to include("não pode estar no passado")
    end
  end
end
