require "rails_helper"

RSpec.describe "Trocar senha", :js do
  let(:user) { create(:user, email: "maria@seed.ap.gov.br", password: "Senha@Forte123", deve_trocar_senha: true) }
  let(:faixa) { "[data-faixa-aviso]" }
  let(:cartao) { "main section + div > section" }

  before { sign_in user }

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "obriga a troca, mostra a faixa de erro e os erros por campo, e libera o sistema" do
      visit root_path
      expect(page).to have_css(faixa, text: "Sua senha precisa ser alterada para continuar usando o SISCOM.")

      fill_in "Senha atual *", with: "Senha@Forte123"
      fill_in "Nova senha *", with: "Seed@123"
      fill_in "Confirmar nova senha *", with: "Seed@123"
      click_on "Salvar nova senha"
      expect(page).to have_css(faixa, text: "Não foi possível trocar a senha.")
        .and have_content("Senha não pode ser a senha padrão antiga")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/senha-mobile.png") if ENV["SCREENSHOT_DIR"]
      expect(sem_rolagem_horizontal?).to be(true)

      fill_in "Senha atual *", with: "Senha@Forte123"
      fill_in "Nova senha *", with: "Nova@Senha456"
      fill_in "Confirmar nova senha *", with: "Nova@Senha456"
      click_on "Salvar nova senha"

      expect(page).to have_content("Senha alterada com sucesso.")
      expect(page).to have_css("#saudacao")
    end

    # Medidas de http://localhost:3102/my-area/password?required=1 no seed, em 390 px.
    it "tem a faixa, o cartão e o botão nas medidas do seed" do
      visit edit_minha_senha_path
      usar_tema("light")

      expect(retangulo(faixa)).to include("x" => 16, "y" => 153, "largura" => 358, "altura" => 73)
      expect(retangulo(cartao)).to include("x" => 16, "y" => 153 + 73 + 24, "largura" => 358)
      expect(tamanhos(campo: "#{cartao} form > div:first-of-type")).to eq(campo: [ 308, 66.8 ])
      botao = retangulo("#{cartao} button[type='submit']")
      expect(botao).to include("altura" => 44, "largura" => be_within(1).of(161.7))
      expect(botao["x"] + botao["largura"]).to be_within(0.5).of(349)
    end
  end

  # Medidas da mesma tela do seed em 1400 px.
  context "quando está no desktop" do
    before do
      visit edit_minha_senha_path
      usar_tema("light")
    end

    it "mostra a faixa reta de aviso entre o cabeçalho de página e o cartão" do
      expect(retangulo(faixa)).to include("x" => 284, "y" => 153, "largura" => 1084, "altura" => 53)
      expect(estilo(faixa, "borderRadius")).to eq("0px")
      expect(estilo(faixa, "backgroundColor")).to eq("rgb(255, 241, 240)")
      expect(estilo(faixa, "borderBottomColor")).to eq("rgb(216, 224, 234)")
      expect(retangulo(cartao)).to include("x" => 284, "y" => 153 + 53 + 24, "largura" => 1084)
    end

    it "tem os campos em duas colunas e o botão à direita" do
      expect(tamanhos(campo: "#{cartao} form > div:first-of-type", caixa: "#{cartao} form > div:first-of-type > div"))
        .to eq(campo: [ 509, 66.8 ], caixa: [ 509, 44 ])
      expect(estilo("#{cartao} form > div:first-of-type > div", "backgroundColor")).to eq("rgb(241, 244, 255)")
      botao = retangulo("#{cartao} button[type='submit']")
      expect(botao).to include("altura" => 44, "largura" => be_within(1).of(161.7))
      expect(botao["x"] + botao["largura"]).to be_within(0.5).of(1343)
    end
  end
end
