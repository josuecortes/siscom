require "rails_helper"

RSpec.describe "Conversas" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { create(:user, nome: "JOAO TECNICO") }
  let(:ana) { create(:user, nome: "ANA TRIADORA") }
  let(:alvo) { create(:user) } # qualquer registro serve de "dono" da conversa

  def sincronizar(ativa: true, participantes: [ maria, joao ], **outros)
    Core::Api.sincronizar_conversa(alvo: alvo, modulo: :ti, titulo: "TI-000001 · SEM INTERNET", ativa: ativa,
                                   participantes: participantes.map { |user| { user: user, url: "/ti/chamados/1" } }, **outros)
  end

  def enviar(conversa, corpo) = post(conversa_mensagens_path(conversa), params: { corpo: corpo }, as: :turbo_stream)

  describe "sincronizar" do
    it "cria a conversa uma vez só, com os participantes e a nota do sistema" do
      conversa = sincronizar(nota_do_sistema: "João assumiu o chamado.")
      sincronizar

      expect(Core::Conversa.sole).to eq(conversa)
      expect(conversa.participantes.pluck(:user_id, :pode_ler, :pode_escrever)).to contain_exactly([ maria.id, true, true ], [ joao.id, true, true ])
      expect(conversa.mensagens.sole).to have_attributes(tipo: "sistema", corpo: "João assumiu o chamado.", autor: nil)
    end

    it "quem deixa de participar perde leitura e escrita enquanto a conversa está ativa" do
      conversa = sincronizar(participantes: [ maria, ana ])
      sincronizar(participantes: [ maria, joao ])

      expect(conversa.participante(ana)).to have_attributes(pode_ler: false, pode_escrever: false, saiu_em: be_present)
      expect(conversa.participante(joao)).to have_attributes(pode_ler: true, pode_escrever: true)
    end

    it "encerrada, fica só para leitura para todos que passaram por ela" do
      conversa = sincronizar(participantes: [ maria, ana ])
      sincronizar(participantes: [ maria, joao ])
      sincronizar(ativa: false, motivo_leitura: "Chamado encerrado.")

      expect(conversa.reload).to have_attributes(status: "somente_leitura", motivo_leitura: "Chamado encerrado.")
      expect(conversa.participantes.pluck(:pode_ler, :pode_escrever)).to all(eq([ true, false ]))
    end
  end

  describe "mensagens" do
    let!(:conversa) { sincronizar }

    it "participante envia; o outro é notificado só na primeira mensagem não lida" do
      sign_in maria

      enviar(conversa, "  Bom dia, a internet caiu de novo.  ")
      enviar(conversa, "É na sala 12.")

      expect(conversa.mensagens.em_ordem.pluck(:corpo, :autor_nome)).to eq([ [ "Bom dia, a internet caiu de novo.", "MARIA OLIVEIRA" ], [ "É na sala 12.", "MARIA OLIVEIRA" ] ])
      expect(joao.notificacoes.sole).to have_attributes(titulo: "Nova mensagem de MARIA OLIVEIRA", url_acao: "/ti/chamados/1")
      expect(conversa.participante(joao).nao_lidas).to eq(2)
      expect(conversa.participante(maria).nao_lidas).to eq(0)
    end

    it "recusa mensagem em branco, de quem não participa e em conversa só para leitura" do
      sign_in maria
      enviar(conversa, "   ")
      expect(response).to have_http_status(:unprocessable_content)

      sign_in ana
      enviar(conversa, "Oi")
      expect(response.body).to include("Esta conversa está só para leitura.")

      sincronizar(ativa: false)
      sign_in maria
      enviar(conversa, "Ainda aí?")
      expect(conversa.mensagens.count).to eq(0)
    end

    it "lista as conversas do usuário com as não lidas e abre a conversa (marcando como lida)" do
      Core::Conversas::EnviarMensagem.call(conversa: conversa, autor: joao, corpo: "Estou indo aí.")
      sign_in maria

      get conversas_path
      expect(response.body).to include("1 conversa(s)", "TI-000001 · SEM INTERNET", "1 não lida(s)", "Aberta")

      get conversa_path(conversa)
      expect(response.body).to include("Estou indo aí.", "JOAO TECNICO", "Digite sua mensagem")
      expect(conversa.participante(maria).nao_lidas).to eq(0)
    end

    it "quem não participa não abre a conversa" do
      sign_in ana

      get conversas_path
      expect(response.body).to include("0 conversa(s)")
      get conversa_path(conversa)
      expect(response).to have_http_status(:not_found)
    end
  end
end
