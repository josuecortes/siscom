require "rails_helper"

RSpec.describe "Página do acompanhamento", :js do
  it "abre pelo menu e cabe no celular sem rolagem horizontal" do
    Transporte::Configuracao.atual.update!(senha_do_painel: "painel123")
    sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "tecnico") }
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Transporte").click
      click_on "Acompanhamento"
    end
    expect(page).to have_css("h1", text: "Acompanhamento").and have_link("Abrir o acompanhamento do Transporte")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/acompanhamento-sobre.png") if ENV["SCREENSHOT_DIR"]

    usar_tela_de_celular
    visit transporte_sobre_acompanhamento_path
    expect(page).to have_link("Abrir o acompanhamento do Transporte")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
