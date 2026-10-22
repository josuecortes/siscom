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

  let(:solicitante) { create(:user, nome: "MARIA OLIVEIRA") }

  it "no navegador moderno usa o painel normal, sem o aviso do modo compatível" do
    sleep 3.5 # passa o prazo em que o modo compatível assumiria

    expect(page).to have_css("#painel_tv[data-moderno='1']")
    expect(page).to have_no_css("#painel_tv[data-compativel]")
    expect(page).to have_no_text("Modo compatível")
    expect(page).to have_button(text: /\ASom:/)
  end

  def solicitar(resumo) = Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: "solicitada", resumo: resumo, saida_em: 1.day.from_now,
                                                         solicitante: solicitante, solicitante_nome: solicitante.nome, solicitante_email: solicitante.email)
  def carregada_em = page.evaluate_script("performance.timeOrigin")


  it "com ?modo=compativel: aviso visível, relógio pela hora do servidor, sem botão de som e navegador resumido" do
    visit transporte_acompanhamento_path(modo: "compativel")

    expect(page).to have_css("#painel_tv[data-compativel='1']")
    expect(page).to have_text(/modo compatível: navegador antigo/i) # o do topo é em maiúsculas
    expect(page).to have_css("#navegador_da_tv", text: /\AChrome \d+ · \d+×\d+\z/)
    expect(page).to have_no_button(text: /\ASom:/)
    hora = texto("hora")
    expect(page).to have_no_css("[data-painel-tv-target='hora']", text: hora, wait: 3) # o relógio anda
  end

  it "no fim do ciclo atualiza em silêncio: a solicitação nova aparece sem a página recarregar" do
    stub_const("PainelDeTv::ATUALIZA_A_CADA", 3)
    visit transporte_acompanhamento_path(modo: "compativel")
    page.find("#painel_tv[data-compativel='1']")
    antes = carregada_em

    nova = solicitar("Reunião na SEAD")

    expect(page).to have_css("#tv_aprovacao .tv-cartao", text: nova.codigo, wait: 8)
    expect(carregada_em).to eq(antes) # não houve recarga (sem o efeito F5)
    expect(page).to have_css("#painel_tv[data-compativel='1']")
  end

  it "com a senha do painel vencida, recarrega e mostra a tela de senha" do
    stub_const("PainelDeTv::ATUALIZA_A_CADA", 3)
    visit transporte_acompanhamento_path(modo: "compativel")
    page.find("#painel_tv[data-compativel='1']")

    page.driver.browser.manage.delete_all_cookies

    expect(page).to have_field("Senha de acesso", wait: 8)
  end
end
