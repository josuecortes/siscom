require "rails_helper"

# Painel de acompanhamento em TVs com navegador antigo: o modo compatível assume quando o painel moderno não inicia.
# No navegador dos testes (moderno) ele é forçado com ?modo=compativel, como o Josue faz para conferir no computador.
RSpec.describe "Painel de TV em modo compatível", :js do
  before do
    Transporte::Configuracao.atual.update!(senha_do_painel: "painel123")
    visit transporte_acompanhamento_path
    fill_in "Senha de acesso", with: "painel123"
    click_on "Entrar no acompanhamento"
    page.find_by_id("painel_tv") # espera o login no painel terminar
  end

  def texto(alvo) = find("[data-painel-tv-target~='#{alvo}']").text

  it "no navegador moderno usa o painel normal, sem o aviso do modo compatível" do
    sleep 3.5 # passa o prazo em que o modo compatível assumiria

    expect(page).to have_css("#painel_tv[data-moderno='1']")
    expect(page).to have_no_css("#painel_tv[data-compativel]")
    expect(page).to have_no_text("Modo compatível")
    expect(page).to have_button(text: /\ASom:/)
  end

  it "com ?modo=compativel: aviso visível, relógio pela hora do servidor, contagem descendo, sem botão de som, e recarrega no fim" do
    stub_const("PainelDeTv::ATUALIZA_A_CADA", 4)
    visit transporte_acompanhamento_path(modo: "compativel")

    expect(page).to have_css("#painel_tv[data-compativel='1']")
    expect(page).to have_text(/modo compatível: navegador antigo/i).and have_text("Modo compatível para navegadores antigos") # o do topo é em maiúsculas
    expect(page).to have_no_button(text: /\ASom:/)
    hora = texto("hora")
    expect(hora).to match(/\A\d{2}:\d{2}:\d{2}\z/)
    expect(page).to have_no_css("[data-painel-tv-target='hora']", text: hora, wait: 3) # o relógio anda
    # No fim do ciclo (4 s neste teste) a página é carregada de novo: o momento de carga da página muda.
    carregada_em = page.evaluate_script("performance.timeOrigin")
    recarregou = 40.times.any? { sleep 0.25; page.evaluate_script("performance.timeOrigin") != carregada_em }
    expect(recarregou).to be(true)
    expect(page).to have_css("#painel_tv[data-compativel='1']") # voltou no mesmo modo
  end
end
