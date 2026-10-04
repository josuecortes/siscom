require "rails_helper"

# Menu do RH com o subgrupo "Referências", conferido contra o seed rodando (admin-shell.tsx, SidebarTreeItem e
# CollapsedFlyoutItem; regra em sis/docs/hr.md, "Reference navigation").
RSpec.describe "RH: menu com subgrupo", :js do
  let(:admin) { create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") } }

  before do
    Rh::Tabelas.garantir_padroes
    sign_in admin
  end

  def menu = "#menu-lateral"
  def subgrupo = "#{menu} details details"

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "começa fechado e abre ao clicar" do
    visit rh_pessoas_path
    usar_tema("light")

    expect(page).to have_css("#{subgrupo}:not([open]) > summary", text: "Referências")
    expect(page).to have_no_link("Cargos", visible: :visible)

    find("#{subgrupo} > summary").click

    within(menu) { expect(page).to have_link("Cargos", href: "/rh/cargos", visible: :visible) }
  end

  it "fica aberto e destacado quando um filho é a página atual, com as medidas do seed" do
    visit rh_tipos_vinculo_path
    usar_tema("light")

    expect(page).to have_css("#{subgrupo}[open]")
    # Subgrupo no nível dos itens do módulo: mesma coluna (x=41, 194 px), py-2 e rótulo sem negrito.
    expect(retangulo("#{subgrupo} > summary")).to include("x" => 41, "largura" => 194, "altura" => 38)
    expect(estilo("#{subgrupo} > summary", "paddingTop")).to eq("8px")
    expect(estilo("#{subgrupo} > summary span:nth-child(2)", "fontWeight")).to eq("400")
    expect(estilo("#{subgrupo} > summary", "backgroundColor")).to match(%r{/ 0\.04})
    # Filhos recuados mais um nível (x=66, 169 px), com 34 px; o ativo com o destaque cheio.
    expect(retangulo("#{subgrupo} a[aria-current='page']")).to include("x" => 66, "largura" => 169, "altura" => 34)
    expect(estilo("#{subgrupo} a[aria-current='page']", "backgroundColor")).to eq("rgb(51, 74, 116)")
    expect(page).to have_css("#{subgrupo} a[aria-current='page']", text: "Vínculos")
    print("rh-menu-subgrupo")
  end

  it "no menu recolhido, mostra o subgrupo dentro do painel flutuante do módulo" do
    visit rh_tipos_vinculo_path
    usar_tema("light")
    click_on "Recolher menu lateral"
    find("#{menu} nav > div:has(a[href='/rh/pessoas']) > details > summary").hover

    flutuante = "#{menu} nav > div:has(a[href='/rh/pessoas']) > [data-flutuante]"
    expect(page).to have_css(flutuante, text: "Navegação do módulo", visible: :visible)
    expect(page).to have_css("#{flutuante} div.rounded-lg", text: "Referências")
    expect(page).to have_no_link("Referências")
    within(flutuante) { expect(page).to have_link("Cargos", href: "/rh/cargos") }
    pessoas = retangulo("#{flutuante} a[href='/rh/pessoas']")
    cargos = retangulo("#{flutuante} a[href='/rh/cargos']")
    expect(cargos["x"]).to eq(pessoas["x"] + 16)
    expect(page).to have_no_css("#{menu} details details [data-flutuante]", visible: :all)
    print("rh-menu-flutuante")
  end
end
