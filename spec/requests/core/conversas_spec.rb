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

    it "participante envia; para o outro conta como não lida, sem ir para o sino" do
      sign_in maria

      enviar(conversa, "  Bom dia, a internet caiu de novo.  ")
      enviar(conversa, "É na sala 12.")

      expect(conversa.mensagens.em_ordem.pluck(:corpo, :autor_nome)).to eq([ [ "Bom dia, a internet caiu de novo.", "MARIA OLIVEIRA" ], [ "É na sala 12.", "MARIA OLIVEIRA" ] ])
      expect(joao.notificacoes).to be_empty
      expect([ Core::Participante.nao_lidas_de(joao), Core::Participante.nao_lidas_de(maria) ]).to eq([ 2, 0 ])
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

    context "com uma mensagem do João para a Maria" do
      before do
        Core::Conversas::EnviarMensagem.call(conversa: conversa, autor: joao, corpo: "Estou indo aí.")
        sign_in maria
      end

      it "mostra o ícone flutuante com o contador em qualquer página" do
        get root_path

        html = Nokogiri::HTML(response.body)
        expect(html.at_css("button[aria-label='Abrir conversas'] #contador_de_conversas").text.strip).to eq("1")
        expect(html.at_css("body")["data-lancador-lista-value"]).to eq("/minha-area/conversas/lancador")
      end

      it "lista no painel flutuante, separando ativas e histórico, com a prévia e as não lidas" do
        get lancador_conversas_path

        expect(response.body).to include("1 mensagem(ns) não lida(s)", "Ativas", "TI-000001 · SEM INTERNET", "Estou indo aí.", "Nenhuma conversa no histórico.")
      end

      it "abrir a conversa no painel marca como lida" do
        get painel_conversa_path(conversa)

        expect(response.body).to include("Estou indo aí.", "JOAO TECNICO", "Digite sua mensagem", "Voltar para conversas")
        expect(Core::Participante.nao_lidas_de(maria)).to eq(0)
      end

      it "o navegador avisa que a mensagem nova foi vista" do
        post lida_conversa_path(conversa)

        expect(response).to have_http_status(:no_content)
        expect(Core::Participante.nao_lidas_de(maria)).to eq(0)
      end

      it "também aparece em Minha área → Conversas" do
        get conversas_path

        expect(response.body).to include("1 conversa(s)", "TI-000001 · SEM INTERNET", "1 não lida(s)", "Aberta", "Abrir conversa")
      end
    end

    it "quem não participa não vê a conversa na lista nem abre no painel" do
      sign_in ana

      get lancador_conversas_path
      expect(response.body).to include("Nenhuma conversa ativa.")
      get painel_conversa_path(conversa)
      expect(response).to have_http_status(:not_found)
    end
  end
end
