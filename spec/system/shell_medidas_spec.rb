require "rails_helper"

# Medidas do shell conferidas contra o seed rodando (admin-shell.tsx e
# page-context-header.tsx), no desktop (1400 px) e no celular (390 px).
RSpec.describe "Shell: medidas iguais às do seed", :js do
  include_context "com catálogo de exemplo"

  let(:user) { create(:user, nome: "MARIA SILVA", email: "maria@seed.ap.gov.br") }
  let(:menu) { "#menu-lateral" }
  let(:gaveta) { "[data-menu-lateral-target='gaveta'] > div" }
  let(:cartao) { "main section + section" }

  before do
    create(:core_concessao, user: user, modulo: "exemplo", papel: "operador")
    sign_in user
  end

  context "quando está no desktop" do
    before do
      visit root_path
      usar_tema("light")
    end

    it "barra do topo: 64 px + borda, translúcida, ao lado do menu de 252 px" do
      expect(retangulo("header")).to include("x" => 252, "y" => 0, "largura" => 1148, "altura" => 65)
      expect(tamanhos(menu: menu, linha: "header > div:first-child")).to eq(menu: [ 252, 900 ], linha: [ 1148, 4 ])
      # --shell-topbar (alfa 0,94) com o /95 do seed = alfa 0,894
      expect(estilo("header", "backgroundColor")).to match(%r{/ 0\.89})
      expect(estilo("header", "backdropFilter")).to eq("blur(8px)")
    end

    it "botões do topo: menu com ícone de 30 px, tema e conta com 40 px" do
      expect(tamanhos(
               menu: "header button[aria-controls='menu-lateral']",
               icone_menu: "header button[aria-controls='menu-lateral'] svg",
               tema: "header button[aria-label='Alternar tema']",
               icone_tema: "header button[aria-label='Alternar tema'] svg"
             )).to eq(menu: [ 32, 32 ], icone_menu: [ 30, 30 ], tema: [ 40, 40 ], icone_tema: [ 18, 18 ])
      expect(retangulo("header button[aria-label='Abrir menu da conta']"))
        .to include("x" => 1336, "y" => 12, "largura" => 40, "altura" => 40)
    end

    it "menu lateral: cabeçalho de 64 px, itens de 42 px com ícone de 20 px e rodapé" do
      expect(tamanhos(
               cabecalho: "#{menu} > div:first-child", marca: "#{menu} > div:first-child a > span",
               item: "#{menu} nav > a", icone_item: "#{menu} nav > a svg",
               grupo: "#{menu} nav summary", icone_grupo: "#{menu} nav summary svg",
               rodape: "#{menu} > div:last-child"
             )).to eq(
               cabecalho: [ 251, 64 ], marca: [ 36, 36 ], item: [ 219, 42 ], icone_item: [ 20, 20 ],
               grupo: [ 219, 42 ], icone_grupo: [ 20, 20 ], rodape: [ 251, 73 ]
             )
      expect(retangulo("#{menu} nav")).to include("x" => 16, "y" => 112.5, "largura" => 219)
    end

    it "item ativo: fundo, borda e filete de destaque à esquerda" do
      expect(estilo("#{menu} nav a[aria-current='page']", "backgroundColor")).to eq("rgb(51, 74, 116)")
      expect(estilo("#{menu} nav a[aria-current='page']", "boxShadow")).to include("3px 0px 0px 0px inset")
    end

    it "itens do grupo: recuados, com 38 px de altura" do
      expect(retangulo("#{menu} details a")).to include("x" => 41, "largura" => 194, "altura" => 38)
    end

    it "conteúdo: cabeçalho de página colado na barra e 24 px até o primeiro cartão" do
      expect([ estilo("main", "paddingLeft"), estilo("main", "paddingBottom") ]).to eq([ "32px", "24px" ])
      expect(retangulo("main section")).to include("x" => 252, "y" => 64, "largura" => 1148, "altura" => 65)
      expect(retangulo(cartao)).to include("x" => 284, "y" => 64 + 65 + 24, "largura" => 1084)
      expect(estilo(cartao, "borderRadius")).to eq("16px")
      expect(estilo(cartao, "boxShadow")).to include("0px 14px 34px 0px")
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
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/conta.png") if ENV["SCREENSHOT_DIR"]

      expect(retangulo("header [role='menu']")).to include("x" => 1152, "y" => 64, "largura" => 224)
      trocar_senha = retangulo("header [role='menu'] a")
      expect(trocar_senha).to include("largura" => 198, "altura" => 36)
      expect(retangulo("header [role='menu'] button"))
        .to include("largura" => 198, "altura" => 36, "y" => trocar_senha["y"] + 36 + 8)
    end
  end

  context "quando o tema é o escuro" do
    before do
      visit root_path
      usar_tema("dark")
    end

    it "usa as cores escuras do seed na barra e no menu" do
      expect(estilo("header", "backgroundColor")).to match(%r{/ 0\.89})
      expect(estilo("header", "borderBottomColor")).to eq("rgb(57, 65, 80)")
      expect(estilo(menu, "backgroundColor")).to eq("rgb(31, 37, 51)")
      expect(estilo("#{menu} nav a[aria-current='page']", "backgroundColor")).to eq("rgb(52, 69, 102)")
      expect(tamanhos(sol: "header button[aria-label='Alternar tema'] span:last-child svg")).to eq(sol: [ 18, 18 ])
    end

    it "usa as cores escuras do seed no cabeçalho de página e no cartão" do
      expect(estilo("main section", "backgroundColor")).to eq("rgba(37, 43, 54, 0.72)")
      expect(estilo(cartao, "backgroundColor")).to eq("rgb(42, 47, 59)")
      expect(estilo(cartao, "boxShadow")).to include("0px 16px 38px 0px")
    end
  end

  context "quando está no celular" do
    before do
      usar_tela_de_celular
      visit root_path
      usar_tema("light")
    end

    it "barra do topo com os botões nas mesmas posições" do
      expect(retangulo("header")).to include("x" => 0, "largura" => 390, "altura" => 65)
      expect(retangulo("header button[aria-label='Abrir menu']"))
        .to include("x" => 16, "y" => 16, "largura" => 32, "altura" => 32)
      expect(tamanhos(icone: "header button[aria-label='Abrir menu'] svg")).to eq(icone: [ 30, 30 ])
      expect(retangulo("header button[aria-label='Abrir menu da conta']")).to include("x" => 334, "y" => 12)
    end

    it "conteúdo com 16 px de margem" do
      expect(estilo("main", "paddingLeft")).to eq("16px")
      expect(retangulo("main section")).to include("x" => 0, "y" => 64, "largura" => 390, "altura" => 65)
      expect(retangulo(cartao)).to include("x" => 16, "y" => 153, "largura" => 358)
    end

    it "gaveta: 320 px, sem o rótulo Navegação, botão de fechar de 40 px" do
      click_on "Abrir menu"
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/gaveta.png") if ENV["SCREENSHOT_DIR"]

      expect(page).to have_no_css(gaveta, text: /navegação/i)
      expect(tamanhos(gaveta: gaveta, icone_fechar: "#{gaveta} button[aria-label='Fechar menu'] svg"))
        .to eq(gaveta: [ 320, 844 ], icone_fechar: [ 38, 38 ])
      expect(retangulo("#{gaveta} nav")).to include("x" => 16, "y" => 84, "largura" => 287)
      expect(retangulo("#{gaveta} button[aria-label='Fechar menu']")).to include("x" => 259, "largura" => 40, "altura" => 40)
      expect(estilo("[data-menu-lateral-target='gaveta']", "backgroundColor")).to eq("rgba(8, 17, 31, 0.8)")
    end
  end
end
