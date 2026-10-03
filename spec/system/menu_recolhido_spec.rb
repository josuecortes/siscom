require "rails_helper"

# Menu lateral recolhido no desktop (porta de CollapsedNavItem / CollapsedFlyoutItem
# de admin-shell.tsx): só ícones, e o grupo abre um painel flutuante.
RSpec.describe "Menu lateral recolhido", :js do
  include_context "com catálogo de exemplo"

  let(:user) { create(:user, nome: "MARIA SILVA", email: "maria@seed.ap.gov.br") }
  let(:menu) { "#menu-lateral" }
  let(:painel) { "#{menu} [data-flutuante]" }

  before do
    create(:core_concessao, user: user, modulo: "exemplo", papel: "operador")
    sign_in user
    visit edit_minha_senha_path
    usar_tema("light")
    click_on "Recolher menu lateral"
  end

  it "mostra só os ícones, com as medidas do seed" do
    expect(page).to have_no_css("#{menu} details a", visible: :visible)
    expect(tamanhos(menu: menu, item: "#{menu} nav > a", grupo: "#{menu} nav summary", icone: "#{menu} nav summary svg"))
      .to eq(menu: [ 72, 900 ], item: [ 39, 46 ], grupo: [ 39, 46 ], icone: [ 20, 20 ])
    expect(retangulo("#{menu} nav")).to include("x" => 16, "y" => 84)
    expect(retangulo("header")).to include("x" => 72, "largura" => 1328)
  end

  it "abre o painel flutuante do grupo ao passar o mouse e navega por ele" do
    expect(page).to have_no_css(painel, visible: :visible)

    find("#{menu} summary").hover

    expect(page).to have_css(painel, text: "Navegação do módulo", visible: :visible)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/flutuante.png") if ENV["SCREENSHOT_DIR"]
    expect(retangulo("#{painel} > div")).to include("x" => 67, "largura" => 288)
    expect(estilo("#{painel} > div", "borderRadius")).to eq("12px")

    within(painel) { click_on "Pessoas" }
    expect(page).to have_css("main h1", text: "Início")
  end

  it "abre o painel flutuante pelo teclado (foco no grupo)" do
    page.execute_script("document.querySelector(#{"#{menu} summary".to_json}).focus()")

    expect(page).to have_css(painel, text: "Pessoas", visible: :visible)
  end

  it "destaca o grupo da página atual" do
    visit root_path

    expect(estilo("#{menu} nav summary", "backgroundColor")).to eq("rgb(51, 74, 116)")
    expect(estilo("#{menu} nav summary", "boxShadow")).to include("3px 0px 0px 0px inset")
  end

  it "mantém o painel flutuante dentro da tela quando ela é baixa" do
    usar_tela(largura: 1400, altura: 200)

    find("#{menu} summary").hover

    expect(page).to have_css(painel, visible: :visible)
    caixa = retangulo("#{painel} > div")
    expect(caixa["y"] + caixa["altura"]).to be <= 192
  end

  it "não existe na gaveta do celular" do
    expect(page).to have_no_css("[data-menu-lateral-target='gaveta'] [data-flutuante]", visible: :all)
  end
end
