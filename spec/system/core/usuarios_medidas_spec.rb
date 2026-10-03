require "rails_helper"

# Medidas da tela de Usuários conferidas contra http://localhost:3102/core/users do seed
# (platform-users-module.tsx, responsive-form-panel.tsx e confirm-dialog.tsx),
# no desktop (1400 px) e no celular (390 px).
RSpec.describe "Administração: usuários com as medidas do seed", :js do
  let(:admin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let!(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }
  let!(:joao) { create(:user, nome: "JOAO SANTOS", email: "joao@seed.ap.gov.br", status: false) }

  before { sign_in admin }

  def cartao = "main section + section"
  def linha_maria = "#user_#{maria.id}"
  def linha_joao = "#user_#{joao.id}"

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  context "quando está no desktop" do
    before do
      visit core_usuarios_path
      usar_tema("light")
    end

    it "tem a ação Novo usuário com ícone e texto no cabeçalho de página" do
      expect(retangulo("main section a[title='Novo usuário']")).to include("y" => 76, "altura" => 40, "largura" => be_within(1).of(144.2))
      expect(retangulo("main section a[title='Novo usuário']")["x"]).to be_within(1).of(1223.8)
      expect(tamanhos(icone: "main section a[title='Novo usuário'] svg")).to eq(icone: [ 16, 16 ])
    end

    it "tem os filtros na grade do seed: busca com lupa, status e dois botões de 44 px" do
      expect(retangulo("#{cartao} form")).to include("x" => 285, "y" => 154, "largura" => 1082, "altura" => 107.8)
      expect(retangulo("#{cartao} input[name='q']")).to include("x" => 309, "y" => 196.8, "largura" => 639.5, "altura" => 44)
      expect(page).to have_css("#{cartao} input[name='q'][type='text']")
      expect(estilo("#{cartao} input[name='q']", "paddingLeft")).to eq("44px")
      expect(retangulo("#{cartao} form .relative svg")).to include("x" => 321, "y" => 210.8, "largura" => 16, "altura" => 16)
      expect(retangulo("#{cartao} select[name='status']")).to include("x" => 964.5, "y" => 196.8, "largura" => 266.5, "altura" => 44)
      expect(retangulo("#{cartao} button[aria-label='Filtrar usuários']")).to include("x" => 1247, "y" => 196.8, "largura" => 44, "altura" => 44)
      expect(retangulo("#{cartao} a[aria-label='Limpar filtros']")).to include("x" => 1299, "y" => 196.8, "largura" => 44, "altura" => 44)
      expect(estilo("#{cartao} input[name='q']", "backgroundColor")).to eq("rgb(241, 244, 255)")
      expect(estilo("#{cartao} input[name='q']", "borderRadius")).to eq("12px")
    end

    it "tem o resumo e o cabeçalho da tabela nas mesmas alturas" do
      expect(retangulo("#usuarios_lista > div:first-child")).to include("x" => 285, "y" => 261.8, "largura" => 1082, "altura" => 53)
      expect(retangulo("#{cartao} table thead th:first-child")).to include("x" => 285, "y" => 314.8, "altura" => 55.1)
      expect(estilo("#{cartao} table thead th", "backgroundColor")).to eq("rgb(241, 244, 255)")
      expect(estilo("#{cartao} table thead th", "fontWeight")).to eq("700")
      expect(estilo("#{linha_maria} td", "paddingTop")).to eq("17.6px")
      expect(estilo("#{linha_maria} td", "paddingLeft")).to eq("20px")
    end

    it "tem os selos de status e de módulos com as cores e o tamanho do seed" do
      expect(estilo("#{linha_maria} td:nth-child(3) span", "backgroundColor")).to eq("rgb(230, 246, 234)")
      expect(estilo("#{linha_maria} td:nth-child(3) span", "color")).to eq("rgb(28, 127, 67)")
      expect(estilo("#{linha_joao} td:nth-child(3) span", "backgroundColor")).to eq("rgb(255, 241, 232)")
      expect(estilo("#{linha_joao} td:nth-child(3) span", "color")).to eq("rgb(168, 90, 23)")
      expect(estilo("#{linha_maria} td:nth-child(4) span", "backgroundColor")).to eq("rgb(245, 247, 251)")
      expect(tamanhos(ativo: "#{linha_maria} td:nth-child(3) span")).to eq(ativo: [ 50.1, 24 ])
      expect(tamanhos(voce: "#user_#{admin.id} td:first-child span")[:voce].last).to eq(23)
      expect(estilo("#user_#{admin.id} td:first-child span", "letterSpacing")).to eq("1.2px")
    end

    it "tem os botões de ação de 36 px separados por 8 px, e apagados quando não se aplicam" do
      botoes = page.evaluate_script(<<~JS)
        [...document.querySelectorAll(#{"#{linha_maria} td:last-child a, #{linha_maria} td:last-child button".to_json})]
          .map((b) => { const r = b.getBoundingClientRect(); return [ r.x, r.width, r.height ] })
      JS
      expect(botoes.map { |_, largura, altura| [ largura, altura ] }).to eq([ [ 36, 36 ] ] * 4)
      expect(botoes.each_cons(2).map { |a, b| (b[0] - a[0]).round(1) }).to eq([ 44, 44, 44 ])
      expect(tamanhos(icone: "#{linha_maria} td:last-child a svg")).to eq(icone: [ 16, 16 ])
      expect(estilo("#user_#{admin.id} td:last-child span[aria-disabled]", "opacity")).to eq("0.5")
    end

    it "usa as cores do tema escuro nos filtros e na tabela" do
      usar_tema("dark")

      expect(estilo("#{cartao} input[name='q']", "backgroundColor")).to eq("rgba(115, 131, 255, 0.12)")
      expect(estilo("#{cartao} input[name='q']", "borderTopColor")).to eq("rgb(57, 65, 80)")
      expect(estilo("#{cartao} table thead th", "backgroundColor")).to eq("rgba(115, 131, 255, 0.12)")
      expect(estilo("#{linha_joao} td", "borderBottomColor")).to eq("rgb(57, 65, 80)")
      expect(estilo("#{linha_maria} td:nth-child(4) span", "backgroundColor")).to eq("rgb(37, 43, 54)")
    end
  end

  context "quando está no celular" do
    before do
      usar_tela_de_celular
      visit core_usuarios_path
      usar_tema("light")
    end

    it "mostra a ação Novo usuário só com o ícone" do
      expect(retangulo("main section a[title='Novo usuário']")).to include("x" => 338, "y" => 78, "largura" => 36, "altura" => 36)
      expect(estilo("main section a[title='Novo usuário'] span", "position")).to eq("absolute") # sr-only
    end

    it "empilha os filtros e deixa os botões lado a lado embaixo" do
      expect(retangulo("#{cartao} input[name='q']")).to include("x" => 41, "y" => 196.8, "largura" => 308, "altura" => 44)
      expect(retangulo("#{cartao} select[name='status']")).to include("x" => 41, "y" => 279.6, "largura" => 308, "altura" => 44)
      expect(retangulo("#{cartao} button[aria-label='Filtrar usuários']")).to include("x" => 41, "y" => 339.6, "largura" => 44, "altura" => 44)
      expect(retangulo("#{cartao} a[aria-label='Limpar filtros']")).to include("x" => 93, "y" => 339.6, "largura" => 44, "altura" => 44)
      expect(retangulo("#usuarios_lista > div:first-child")).to include("x" => 17, "y" => 404.6, "largura" => 356, "altura" => 53)
    end

    it "rola a tabela dentro do cartão, sem rolagem horizontal da página" do
      expect(sem_rolagem_horizontal?).to be(true)
      expect(retangulo("#{cartao} .overflow-x-auto")).to include("x" => 17, "y" => 457.6, "largura" => 356)
      expect(page.evaluate_script("document.querySelector(#{"#{cartao} .overflow-x-auto".to_json}).scrollWidth")).to be > 356
      print("usuarios-lista-celular")
    end
  end
end
