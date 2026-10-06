require "rails_helper"

RSpec.describe "Arquivos de até 1 MB e sessão que expira com o formulário aberto", :js do
  let(:user) { create(:user, nome: "MARIA OLIVEIRA", password: "Senha@Forte123") }

  before { sign_in user }

  it "a imagem grande é reduzida sozinha para caber em 1 MB e é gravada" do
    visit meu_perfil_path
    attach_file "Nova imagem do perfil", png_grande(lado: 1400)

    expect(page).to have_css("[data-arquivo-aviso]", text: "Imagem reduzida para caber em 1 MB")
    expect(page.evaluate_script("(() => { const a = document.querySelector('#user_avatar').files[0]; return [ a.type, a.size <= 1048576, a.name.endsWith('foto-grande.jpg') ] })()")).to eq([ "image/jpeg", true, true ])
    click_on "Trocar imagem"
    expect(page).to have_content("Imagem do perfil atualizada")
    expect(user.reload.avatar.blob).to have_attributes(content_type: "image/jpeg", byte_size: be <= 1.megabyte)
  end

  it "o documento grande é recusado na hora, antes de enviar" do
    visit meu_perfil_path
    page.execute_script("document.querySelector('#user_avatar').removeAttribute('accept')")
    attach_file "Nova imagem do perfil", pdf_grande

    expect(page).to have_css("[data-arquivo-aviso][role='alert']", text: "O limite é 1 MB por arquivo")
    expect(page.evaluate_script("document.querySelector('#user_avatar').files.length")).to eq(0)
  end

  context "com um formulário aberto há muito tempo" do
    # O navegador acha que passaram 10 minutos desde a última conferência da sessão.
    def envelhecer = page.execute_script("const real = Date.now.bind(Date); Date.now = () => real() + 10 * 60 * 1000")

    it "com a sessão ainda válida, confere e envia normalmente" do
      visit edit_minha_senha_path
      fill_in "Senha atual *", with: "Senha@Forte123"
      fill_in "Nova senha *", with: "Nova@Senha456"
      fill_in "Confirmar nova senha *", with: "Nova@Senha456"
      envelhecer

      click_on "Salvar nova senha"

      expect(page).to have_content("Senha alterada")
      expect(user.reload.valid_password?("Nova@Senha456")).to be(true)
    end

    it "com a sessão expirada, avisa e não perde o que foi preenchido" do
      visit edit_minha_senha_path
      fill_in "Senha atual *", with: "Senha@Forte123"
      fill_in "Nova senha *", with: "Nova@Senha456"
      fill_in "Confirmar nova senha *", with: "Nova@Senha456"
      envelhecer
      LoginDeSistema.limpar # a sessão acabou: sem o login dos testes e sem o cookie
      page.driver.browser.manage.delete_all_cookies

      click_on "Salvar nova senha"

      expect(page).to have_css("#confirmacao", text: "Sessão expirada").and have_button("Entrar em outra aba")
      within("#confirmacao") { click_on "Cancelar" }
      expect(page).to have_current_path(edit_minha_senha_path)
      expect(page).to have_field("Nova senha *", with: "Nova@Senha456")
    end
  end
end
