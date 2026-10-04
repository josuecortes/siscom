require "rails_helper"

RSpec.describe "TI: catálogo", :js do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }

  before do
    create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }
    sign_in admin
  end

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "cadastra um grupo técnico pelo menu e define os membros" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "TI").click
      find("summary", text: "Administração").click
      click_on "Grupos técnicos"
    end
    click_on "Novo grupo"
    expect(page).to have_css("[role='dialog'] h2", text: "Cadastrar grupo técnico")
    fill_in "Nome *", with: "Redes"
    fill_in "Descrição", with: "Rede e internet"
    print("ti-grupo-painel")
    click_on "Salvar grupo"

    expect(page).to have_css("#avisos", text: "Grupo técnico criado com sucesso.")
    within("tr", text: "REDES") { click_on "Gerenciar membros" }
    expect(page).to have_css("[role='dialog'] h2", text: "Gerenciar membros de REDES")
    escolher_no_autocomplete "Adicionar membro", digitar: "joao", opcao: "JOAO TECNICO"
    click_on "Adicionar"
    expect(page).to have_content("JOAO TECNICO entrou no grupo.")
    print("ti-grupo-membros")
    within("[role='dialog']") { expect(page).to have_button("Remover JOAO TECNICO") }
    click_on "Concluir"

    expect(page).to have_no_css("[role='dialog']")
    within("tr", text: "REDES") { expect(page).to have_content("1 membro(s)").and have_content("JOAO TECNICO") }
    expect(Ti::GrupoTecnico.sole.membros.map(&:nome)).to eq([ "JOAO TECNICO" ])
    print("ti-grupos-lista")
  end

  it "cadastra um perfil de abertura e dá o perfil a um usuário pela tela de permissões" do
    visit ti_perfis_abertura_path
    click_on "Novo perfil"
    fill_in "Nome *", with: "Diretor de escola"
    click_on "Salvar perfil"
    expect(page).to have_css("#avisos", text: "Perfil de abertura criado com sucesso.")

    visit ti_permissoes_path
    within("tr", text: "JOAO TECNICO") { click_on "Gerenciar perfis de abertura" }
    check "DIRETOR DE ESCOLA"
    click_on "Salvar perfis"

    expect(page).to have_css("#avisos", text: "Perfis de abertura de JOAO TECNICO atualizados.")
    within("tr", text: "JOAO TECNICO") { expect(page).to have_content("DIRETOR DE ESCOLA") }
  end

  it "no celular as listas e os painéis não criam rolagem horizontal" do
    create(:ti_categoria, nome: "Rede")
    usar_tela_de_celular
    visit ti_categorias_path
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Nova categoria"
    expect(page).to have_css("[role='dialog'] h2", text: "Nova categoria")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
