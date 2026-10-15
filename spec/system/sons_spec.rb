require "rails_helper"

# Alertas sonoros: a página anota cada toque em window.siscomSonsTocados (o áudio em si não dá para ouvir no teste).
RSpec.describe "Alertas sonoros", :js do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { create(:user, nome: "JOAO TECNICO") }

  def tocados = page.evaluate_script("window.siscomSonsTocados || []")

  # O pedido de som chega pelo tempo real logo depois do aviso ou do contador: espera até ele tocar (ou desistir).
  def tocados_depois(quantos)
    50.times do
      break if tocados.size >= quantos

      sleep 0.1
    end
    tocados
  end
  def notificar(titulo) = Core::Api.notificar(destinatarios: maria, evento: "core.teste.aviso", titulo: titulo, ator: nil).first

  def entrar
    sign_in maria
    visit root_path
    # Todos os canais de tempo real da página conectados (notificações e conversas), senão o aviso enviado chega antes e se perde.
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, minimum: 2)
    expect(page).to have_no_css("turbo-cable-stream-source:not([connected])", visible: :all)
  end

  it "a notificação toca uma vez; a mesma notificação em outra aba não toca de novo, só uma nova" do
    entrar

    primeira = notificar("Primeiro aviso")
    expect(page).to have_css("#avisos", text: "Primeiro aviso")
    expect(tocados_depois(1)).to eq([ "notificacao" ])

    # Outra aba aberta recebe o mesmo pedido: já tocou neste navegador.
    page.execute_script("document.querySelector('#sons').insertAdjacentHTML('beforeend', '<span data-controller=\"som\" data-som-tipo-value=\"notificacao\" data-som-numero-value=\"#{primeira.id}\"></span>')")
    visit root_path # abrir o siscom de novo com a notificação ainda não lida
    expect(page).to have_css("[data-sino-contador]", text: "1")
    expect(tocados).to eq([])

    notificar("Segundo aviso")
    expect(page).to have_css("#avisos", text: "Segundo aviso")
    expect(tocados_depois(1)).to eq([ "notificacao" ])
  end

  it "a mensagem do chat toca um som diferente, só para quem recebe" do
    conversa = Core::Api.sincronizar_conversa(alvo: joao, modulo: :ti, titulo: "TI-000001 · SEM INTERNET", ativa: true,
                                              participantes: [ maria, joao ].map { |user| { user: user, url: "/ti/chamados/1" } })
    entrar

    Core::Conversas::EnviarMensagem.call(conversa: conversa, autor: joao, corpo: "Estou indo aí.")
    expect(page).to have_css("#contador_de_conversas", text: "1")
    expect(tocados_depois(1)).to eq([ "mensagem" ])

    Core::Conversas::EnviarMensagem.call(conversa: conversa, autor: maria, corpo: "Obrigada!") # a própria mensagem não toca
    sleep 0.5
    expect(tocados).to eq([ "mensagem" ])
  end

  describe "painel de acompanhamento" do
    before do
      create(:core_concessao, user: maria, modulo: "transporte", papel: "solicitante")
      Transporte::Configuracao.atual.update!(senha_do_painel: "painel123")
    end

    def solicitar(status = "solicitada")
      Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: status, resumo: "Reunião na SEAD", saida_em: 2.days.from_now, solicitante: maria,
                                      solicitante_nome: maria.nome, solicitante_email: maria.email)
    end

    it "toca quando chega uma solicitação na primeira coluna, e não toca de novo ao atualizar a tela" do
      solicitar # já estava lá quando o painel abriu: só é anotada
      visit transporte_acompanhamento_path
      fill_in "Senha de acesso", with: "painel123"
      click_on "Entrar no acompanhamento"
      expect(page).to have_css("#tv_aprovacao .tv-cartao", count: 1).and have_button("Som: ligado")
      sleep 0.4
      expect(tocados).to eq([])

      solicitar("aprovada") # outra coluna: não toca
      nova = solicitar
      visit transporte_acompanhamento_path
      expect(page).to have_css("#tv_aprovacao .tv-cartao", count: 2).and have_content(nova.codigo)
      sleep 0.4
      expect(tocados).to eq([ "painel" ])

      visit transporte_acompanhamento_path # atualizou e ela continua lá
      expect(page).to have_css("#tv_aprovacao .tv-cartao", count: 2)
      sleep 0.4
      expect(tocados).to eq([])
    end
  end
end
