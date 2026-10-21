require "rails_helper"

# Balões de não lidas que "pulam" e aviso no título da aba do navegador.
RSpec.describe "Avisos no balão e na aba", :js do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }

  def notificar = Core::Api.notificar(destinatarios: maria, evento: "core.teste.aviso", titulo: "Aviso de teste", ator: nil)

  def esconder_aba(escondida)
    page.execute_script("Object.defineProperty(document, 'hidden', { configurable: true, get: () => #{escondida} }); document.dispatchEvent(new Event('visibilitychange'))")
  end

  def titulos_por(segundos) = (segundos * 4).times.map { sleep 0.25; page.title }.uniq

  before do
    sign_in maria
    visit root_path
    page.find("turbo-cable-stream-source[connected]", visible: :all, match: :first)
  end

  it "o balão do sino anima e o título ganha o total de não lidas" do
    notificar

    expect(page).to have_css("[data-sino-contador]", text: "1")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-sino-contador]')).animationName")).to eq("balao-pulso")
    expect(page).to have_title("(1) Início · Siscom")
  end

  it "com a aba escondida, o título alterna com o aviso e para quando a pessoa volta" do
    esconder_aba(true)
    notificar
    expect(page).to have_css("[data-sino-contador]", text: "1")

    expect(titulos_por(5)).to include("🔔 Nova notificação", "(1) Início · Siscom")
    esconder_aba(false)
    expect(page).to have_title("(1) Início · Siscom")
    expect(titulos_por(3)).to eq([ "(1) Início · Siscom" ])
  end

  it "mensagem nova no chat com a aba escondida: o balão do chat anima e o aviso é de mensagem" do
    joao = create(:user, nome: "JOAO TECNICO")
    conversa = Core::Api.sincronizar_conversa(alvo: joao, modulo: :ti, titulo: "TI-000001 · SEM INTERNET", ativa: true,
                                              participantes: [ maria, joao ].map { |user| { user: user, url: "/ti/chamados/1" } })
    esconder_aba(true)

    Core::Conversas::EnviarMensagem.call(conversa: conversa, autor: joao, corpo: "Estou indo aí.")

    expect(page).to have_css("[data-conversas-contador]", text: "1")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-conversas-contador]')).animationName")).to eq("balao-pulso")
    expect(titulos_por(5)).to include("💬 Nova mensagem")
  end
end
