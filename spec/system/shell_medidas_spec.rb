require "rails_helper"

# Medidas do shell conferidas contra o seed rodando (admin-shell.tsx e
# page-context-header.tsx), no desktop (1400 px) e no celular (390 px).
RSpec.describe "Shell: medidas iguais às do seed", :js do
  include_context "com catálogo de exemplo"

  let(:user) { create(:user, nome: "MARIA SILVA", email: "maria@seed.ap.gov.br") }

  before do
    create(:core_concessao, user: user, modulo: "exemplo", papel: "operador")
    sign_in user
  end

  def tamanho(seletor)
    retangulo(seletor).values_at("largura", "altura")
  end

  context "no desktop" do
    before do
      visit root_path
      usar_tema("light")
    end

    it "barra do topo: 64 px + borda, translúcida, ao lado do menu de 252 px" do
      expect(retangulo("header")).to include("x" => 252, "y" => 0, "largura" => 1148, "altura" => 65)
      expect(tamanho("#menu-lateral")).to eq([ 252, 900 ])
      # --shell-topbar (alfa 0,94) com /95 do seed = alfa 0,894
      expect(estilo("header", "backgroundColor")).to match(%r{/ 0\.89})
      expect(estilo("header", "backdropFilter")).to eq("blur(8px)")
      expect(tamanho("header > div:first-child")).to eq([ 1148, 4 ])
    end

    it "botões do topo: menu com ícone de 30 px, tema e conta com 40 px" do
      expect(tamanho("header button[aria-controls='menu-lateral']")).to eq([ 32, 32 ])
      expect(tamanho("header button[aria-controls='menu-lateral'] svg")).to eq([ 30, 30 ])
      expect(tamanho("header button[aria-label='Alternar tema']")).to eq([ 40, 40 ])
      expect(tamanho("header button[aria-label='Alternar tema'] svg")).to eq([ 18, 18 ])
      expect(retangulo("header button[aria-label='Abrir menu da conta']")).to include("x" => 1336, "y" => 12, "largura" => 40, "altura" => 40)
    end

    it "menu lateral: cabeçalho de 64 px, rótulo, itens de 42 px com ícone de 20 px e rodapé" do
      expect(retangulo("#menu-lateral > div:first-child")).to include("altura" => 64)
      expect(tamanho("#menu-lateral > div:first-child a > span")).to eq([ 36, 36 ])
      expect(retangulo("#menu-lateral nav")).to include("x" => 16, "y" => 112.5, "largura" => 219)
      expect(tamanho("#menu-lateral nav > a")).to eq([ 219, 42 ])
      expect(tamanho("#menu-lateral nav > a svg")).to eq([ 20, 20 ])
      expect(tamanho("#menu-lateral nav summary")).to eq([ 219, 42 ])
      expect(tamanho("#menu-lateral nav summary svg")).to eq([ 20, 20 ])
      expect(tamanho("#menu-lateral > div:last-child")).to eq([ 251, 73 ])
    end

    it "item ativo: fundo, borda e filete de destaque à esquerda" do
      expect(estilo("#menu-lateral nav a[aria-current='page']", "backgroundColor")).to eq("rgb(51, 74, 116)")
      expect(estilo("#menu-lateral nav a[aria-current='page']", "boxShadow")).to include("3px 0px 0px 0px inset")
    end

    it "itens do grupo: recuados, com 38 px de altura" do
      expect(retangulo("#menu-lateral details a")).to include("x" => 41, "largura" => 194, "altura" => 38)
    end

    it "conteúdo: cabeçalho de página colado na barra e 24 px até o primeiro cartão" do
      expect(estilo("main", "paddingLeft")).to eq("32px")
      expect(estilo("main", "paddingBottom")).to eq("24px")
      cabecalho = retangulo("main section")
      expect(cabecalho).to include("x" => 252, "y" => 64, "largura" => 1148, "altura" => 65)
      cartao = retangulo("main section + section")
      expect(cartao).to include("x" => 284, "y" => cabecalho["y"] + cabecalho["altura"] + 24, "largura" => 1084)
      expect(estilo("main section + section", "borderRadius")).to eq("16px")
      expect(estilo("main section + section", "boxShadow")).to include("0px 14px 34px 0px")
    end

    it "o botão do menu diz o que o clique vai fazer" do
      click_on "Recolher menu lateral"
      expect(page).to have_button("Expandir menu lateral")
      expect(page).to have_css("header button[aria-controls='menu-lateral'][aria-expanded='false']")

      click_on "Expandir menu lateral"
      expect(page).to have_button("Recolher menu lateral")
    end

    it "menu da conta: painel de 224 px com itens de 36 px" do
      click_on "Abrir menu da conta"

      painel = retangulo("header [role='menu']")
      expect(painel).to include("x" => 1152, "y" => 64, "largura" => 224)
      expect(tamanho("header [role='menu'] a")).to eq([ 198, 36 ])
      trocar = retangulo("header [role='menu'] a")
      sair = retangulo("header [role='menu'] button")
      expect(sair).to include("largura" => 198, "altura" => 36, "y" => trocar["y"] + 36 + 8)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/conta.png") if ENV["SCREENSHOT_DIR"]
    end
  end

  context "no tema escuro" do
    before do
      visit root_path
      usar_tema("dark")
    end

    it "usa as cores escuras do seed na barra, no menu, no cabeçalho de página e no cartão" do
      expect(estilo("header", "backgroundColor")).to match(%r{/ 0\.89})
      expect(estilo("header", "borderBottomColor")).to eq("rgb(57, 65, 80)")
      expect(estilo("#menu-lateral", "backgroundColor")).to eq("rgb(31, 37, 51)")
      expect(estilo("#menu-lateral nav a[aria-current='page']", "backgroundColor")).to eq("rgb(52, 69, 102)")
      expect(estilo("main section", "backgroundColor")).to eq("rgba(37, 43, 54, 0.72)")
      expect(estilo("main section + section", "backgroundColor")).to eq("rgb(42, 47, 59)")
      expect(estilo("main section + section", "boxShadow")).to include("0px 16px 38px 0px")
      expect(tamanho("header button[aria-label='Alternar tema'] span:last-child svg")).to eq([ 18, 18 ])
    end
  end

  context "no celular" do
    before do
      usar_tela_de_celular
      visit root_path
      usar_tema("light")
    end

    it "barra do topo e conteúdo com 16 px de margem" do
      expect(retangulo("header")).to include("x" => 0, "largura" => 390, "altura" => 65)
      expect(retangulo("header button[aria-label='Abrir menu']")).to include("x" => 16, "y" => 16, "largura" => 32, "altura" => 32)
      expect(tamanho("header button[aria-label='Abrir menu'] svg")).to eq([ 30, 30 ])
      expect(retangulo("header button[aria-label='Abrir menu da conta']")).to include("x" => 334, "y" => 12)
      expect(estilo("main", "paddingLeft")).to eq("16px")
      expect(retangulo("main section")).to include("x" => 0, "y" => 64, "largura" => 390, "altura" => 65)
      expect(retangulo("main section + section")).to include("x" => 16, "y" => 153, "largura" => 358)
    end

    it "gaveta: 320 px, sem o rótulo Navegação, botão de fechar de 40 px" do
      click_on "Abrir menu"

      gaveta = "[data-menu-lateral-target='gaveta'] > div"
      expect(tamanho(gaveta)).to eq([ 320, 844 ])
      expect(page).to have_no_css(gaveta, text: /navegação/i)
      expect(retangulo("#{gaveta} nav")).to include("x" => 16, "y" => 84, "largura" => 287)
      expect(retangulo("#{gaveta} button[aria-label='Fechar menu']")).to include("x" => 259, "largura" => 40, "altura" => 40)
      expect(tamanho("#{gaveta} button[aria-label='Fechar menu'] svg")).to eq([ 38, 38 ])
      expect(estilo("[data-menu-lateral-target='gaveta']", "backgroundColor")).to eq("rgba(8, 17, 31, 0.8)")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/gaveta.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
