require "rails_helper"

RSpec.describe "Administração: auditoria", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  before do
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    sign_in superadmin
  end

  it "mostra na auditoria o que acabou de ser feito na tela de usuários" do
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Desativar usuário" }
    within("#confirmacao") { click_on "Desativar usuário" }
    expect(page).to have_css("#avisos", text: "Usuário desativado com sucesso.")

    within("#menu-lateral") { click_on "Auditoria" }

    expect(page).to have_css("h1", text: "Auditoria")
    within("tbody tr:first-child") do
      expect(page).to have_content("Usuário desativado")
      expect(page).to have_content("ADMIN DA SILVA MARIA OLIVEIRA")
    end
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/auditoria.png") if ENV["SCREENSHOT_DIR"]

    fill_in "De", with: "01012020"
    expect(page).to have_field("De", with: "01/01/2020") # máscara dd/mm/aaaa
    find("body").click
    expect(page).to have_current_path(%r{de=01%2F01%2F2020})
    expect(page).to have_content("Usuário desativado")

    escolher_no_autocomplete "Evento", digitar: "permiss", opcao: "Permissão concedida"
    expect(page).to have_content("Nenhum registro encontrado")
    expect(page).to have_current_path(/evento=core.acesso.papel_concedido/)
  end

  # A tela não existe no seed: segue as medidas das outras listagens (filtros, resumo e tabela de Usuários).
  it "tem filtros, resumo e tabela nas mesmas medidas das outras listagens" do
    Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: superadmin, ator: superadmin)
    visit core_auditoria_path
    usar_tema("light")
    cartao = "main section + section"

    expect(retangulo("#{cartao} form")).to include("x" => 285, "y" => 154, "largura" => 1082, "altura" => 107.8)
    expect(tamanhos(busca: "#{cartao} input[name='q']", evento: "#{cartao} #evento", de: "#{cartao} input[name='de']",
                    ate: "#{cartao} input[name='ate']").transform_values(&:last)).to eq(busca: 44, evento: 44, de: 44, ate: 44)
    expect(retangulo("#{cartao} button[aria-label='Filtrar registros']")).to include("x" => 1247, "y" => 196.8, "largura" => 44, "altura" => 44)
    expect(retangulo("#{cartao} a[aria-label='Limpar filtros']")).to include("x" => 1299, "y" => 196.8, "largura" => 44, "altura" => 44)
    expect(retangulo("#auditoria_lista > div:first-child")).to include("x" => 285, "y" => 261.8, "largura" => 1082, "altura" => 53)
    expect(retangulo("#{cartao} table thead th:first-child")).to include("x" => 285, "y" => 314.8, "altura" => 55.1)
    expect(estilo("#{cartao} tbody td", "paddingTop")).to eq("17.6px")
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "empilha os filtros na largura toda e rola a tabela dentro do cartão" do
      Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: superadmin, ator: superadmin)
      visit core_auditoria_path
      cartao = "main section + section"

      expect(tamanhos(busca: "#{cartao} input[name='q']", evento: "#{cartao} #evento", de: "#{cartao} input[name='de']",
                      ate: "#{cartao} input[name='ate']")).to eq(busca: [ 308, 44 ], evento: [ 308, 44 ], de: [ 308, 44 ], ate: [ 308, 44 ])
      expect(retangulo("#{cartao} button[aria-label='Filtrar registros']")).to include("x" => 41, "largura" => 44, "altura" => 44)
      expect(retangulo("#{cartao} a[aria-label='Limpar filtros']")).to include("x" => 93, "largura" => 44, "altura" => 44)
      expect(retangulo("#{cartao} .overflow-x-auto")).to include("x" => 17, "largura" => 356)
      expect(sem_rolagem_horizontal?).to be(true)
    end

    it "não cria rolagem horizontal" do
      Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: superadmin, ator: superadmin)
      visit core_auditoria_path

      expect(page).to have_content("1 registro(s) de auditoria")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/auditoria-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
