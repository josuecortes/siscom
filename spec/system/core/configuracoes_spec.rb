require "rails_helper"

RSpec.describe "Administração: configurações", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  before { sign_in superadmin }

  it "muda o nome e o ícone da marca e vê o resultado na hora" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Administração").click
      click_on "Configurações"
    end
    expect(page).to have_css("h1", text: "Configurações")

    fill_in "Nome da marca (computador) *", with: "Portal SEED"
    fill_in "Nome no cabeçalho (computador) *", with: "Portal da Educação"
    attach_file "Arquivo do ícone da marca", Rails.root.join("spec/fixtures/files/avatar.png")
    click_on "Salvar configurações"

    expect(page).to have_css("#avisos", text: "Configurações salvas.")
    expect(page).to have_css("#menu-lateral", text: "Portal SEED")
    expect(page).to have_css("header", text: "Portal da Educação")
    expect(page).to have_css("#menu-lateral a img")
    expect(page).to have_content("Remover a imagem atual")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/configuracoes.png") if ENV["SCREENSHOT_DIR"]
  end

  # Medidas de /core/settings do seed (core-settings-module.tsx), em 1400 px.
  it "tem os blocos, os campos e as caixas de seleção nas medidas do seed" do
    visit core_configuracoes_path
    usar_tema("light")
    bloco = "main form > section"

    expect(retangulo("#{bloco}:nth-of-type(1)")).to include("x" => 309, "y" => 174, "largura" => 1034)
    primeiro = retangulo("#{bloco}:nth-of-type(1)")
    expect(retangulo("#{bloco}:nth-of-type(2)")["y"]).to be_within(0.2).of(primeiro["y"] + primeiro["altura"] + 24)
    expect(estilo("#{bloco} h2", "fontSize")).to eq("16px")
    expect(retangulo("#configuracao_nome_marca_web")).to include("x" => 326, "largura" => 492, "altura" => 44)
    expect(retangulo("#configuracao_nome_marca_celular")).to include("x" => 834, "largura" => 492, "altura" => 44)
    caixa = "#{bloco}:nth-of-type(1) label:has(input[type='checkbox'])"
    expect(retangulo(caixa)).to include("x" => 326, "largura" => 494, "altura" => 38)
    expect(estilo(caixa, "color")).to eq("rgb(91, 102, 117)")
    expect(estilo(caixa, "backgroundColor")).to eq("rgb(241, 244, 255)")
    expect(retangulo("#configuracao_icone_marca")).to include("largura" => 492, "altura" => 44)
    botao = retangulo("main form button[type='submit']")
    expect(botao).to include("altura" => 44, "largura" => be_within(1).of(182))
    expect(botao["x"] + botao["largura"]).to be_within(0.5).of(1343)
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      visit core_configuracoes_path

      expect(page).to have_css("h1", text: "Configurações")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/configuracoes-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
