require "rails_helper"

RSpec.describe "Login" do
  before { create(:user, nome: "MARIA SILVA", email: "maria@seed.ap.gov.br", password: "Senha@Forte123") }

  it "entra e vê a tela inicial" do
    visit root_path

    fill_in "E-mail", with: "maria@seed.ap.gov.br"
    fill_in "Senha", with: "Senha@Forte123"
    click_on "Entrar"

    expect(page).to have_content("Olá, MARIA SILVA")
  end

  it "mostra erro com senha errada" do
    visit new_user_session_path

    fill_in "E-mail", with: "maria@seed.ap.gov.br"
    fill_in "Senha", with: "errada"
    click_on "Entrar"

    expect(page).to have_content("E-mail ou senha inválida")
  end

  # Medidas da tela /login do seed (platform-login-hero.tsx + platform-login-form.tsx).
  describe "medidas iguais às do seed", :js do
    let(:painel) { "body > div > div > div" }

    before { visit new_user_session_path }

    context "quando está no desktop" do
      it "é um painel central de 760 px, arredondado e com sombra" do
        expect(retangulo(painel)).to include("x" => 320, "y" => 176, "largura" => 760, "altura" => 548)
        expect(estilo(painel, "borderRadius")).to eq("28px")
        expect(estilo(painel, "boxShadow")).to include("rgba(31, 36, 55, 0.12) 0px 30px 70px 0px")
        expect(retangulo("#{painel} > div:first-child")).to include("x" => 321, "y" => 177, "largura" => 758, "altura" => 4)
      end

      it "tem a marca, o título e os campos nas mesmas posições" do
        expect(retangulo("#{painel} [data-login-icone='web'] > span")).to include("x" => 396, "y" => 225, "largura" => 44, "altura" => 44)
        expect(retangulo("#{painel} h1")).to include("x" => 396, "y" => 301, "largura" => 608, "altura" => 56.4)
        expect(retangulo("#{painel} input[type='email']").values_at("x", "y", "largura")).to eq([ 397, 433.2, 606 ])
        expect(tamanhos(caixa: "#{painel} form .h-12", olho: "#{painel} form button[type='button']"))
          .to eq(caixa: [ 608, 48 ], olho: [ 48, 46 ])
        expect(estilo("#{painel} [data-login-titulo]", "letterSpacing")).to eq("1.98px")
      end

      it "tem a caixa de lembrar e o botão Entrar como no seed" do
        expect(retangulo("#{painel} input[type='checkbox']")).to include("x" => 396, "y" => 593, "largura" => 16, "altura" => 16)
        expect(estilo("#{painel} input[type='checkbox']", "accentColor")).to eq("auto")
        expect(retangulo("#{painel} button[type='submit']")).to include("x" => 396, "y" => 635, "altura" => 44, "largura" => be_within(1).of(89.5))
      end
    end

    context "quando está no celular" do
      before do
        usar_tela_de_celular
        visit new_user_session_path
      end

      it "ocupa a tela inteira, sem cartão" do
        expect(retangulo(painel)).to include("x" => 0, "y" => 0, "largura" => 390, "altura" => 844)
        expect(estilo(painel, "borderRadius")).to eq("0px")
        expect(estilo(painel, "boxShadow")).to eq("none")
        expect(sem_rolagem_horizontal?).to be(true)
        page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/login-celular.png") if ENV["SCREENSHOT_DIR"]
      end

      it "tem a marca empilhada, campos e botão na largura toda" do
        expect(retangulo("#{painel} [data-login-icone='celular'] > span")).to include("x" => 24, "y" => 36, "largura" => 44, "altura" => 44)
        expect(retangulo("#{painel} h1")).to include("x" => 24, "y" => 112, "largura" => 342)
        expect(tamanhos(caixa: "#{painel} form .h-12", botao: "#{painel} button[type='submit']"))
          .to eq(caixa: [ 342, 48 ], botao: [ 342, 44 ])
        expect(estilo("#{painel} [data-login-titulo]", "letterSpacing")).to eq("1.76px")
      end
    end
  end
end
