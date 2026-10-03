require "rails_helper"

RSpec.describe "Trocar senha", :js do
  let(:user) { create(:user, email: "maria@seed.ap.gov.br", password: "Senha@Forte123", deve_trocar_senha: true) }

  before do
    sign_in user
    usar_tela_de_celular
  end

  it "obriga a troca, mostra erros por campo e libera o sistema, no celular" do
    visit root_path
    expect(page).to have_content("Sua senha precisa ser alterada para continuar usando o SISCOM.")

    fill_in "Senha atual *", with: "Senha@Forte123"
    fill_in "Nova senha *", with: "Seed@123"
    fill_in "Confirmar nova senha *", with: "Seed@123"
    click_on "Salvar nova senha"
    expect(page).to have_content("Senha não pode ser a senha padrão antiga")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/senha-mobile.png") if ENV["SCREENSHOT_DIR"]
    expect(sem_rolagem_horizontal?).to be(true)

    fill_in "Senha atual *", with: "Senha@Forte123"
    fill_in "Nova senha *", with: "Nova@Senha456"
    fill_in "Confirmar nova senha *", with: "Nova@Senha456"
    click_on "Salvar nova senha"

    expect(page).to have_content("Senha alterada com sucesso.")
    expect(page).to have_content("Olá,")
  end
end
