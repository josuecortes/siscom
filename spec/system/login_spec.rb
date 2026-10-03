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
end
