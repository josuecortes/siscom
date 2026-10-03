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
  def painel = "[role='dialog']"
  def confirmacao = "[role='alertdialog']"
  def rolagem_travada? = page.evaluate_script("getComputedStyle(document.documentElement).overflowY") == "hidden"

  def abrir_painel
    click_on "Novo usuário"
    expect(page).to have_css("#{painel} h2", text: "Cadastrar usuário")
  end

  def abrir_confirmacao
    page.execute_script("document.querySelector(#{"#{linha_maria} button[title='Desativar usuário']".to_json}).click()")
    expect(page).to have_css("#{confirmacao} h2", text: "Desativar usuário")
  end

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
      # Selos de status ficam com as cores claras do seed também no tema escuro.
      expect(estilo("#{linha_maria} td:nth-child(3) span", "backgroundColor")).to eq("rgb(230, 246, 234)")
      expect(estilo("#{linha_joao} td:nth-child(3) span", "backgroundColor")).to eq("rgb(255, 241, 232)")
    end
  end

  context "quando o painel de formulário está aberto no desktop" do
    before do
      visit core_usuarios_path
      usar_tema("light")
      abrir_painel
    end

    it "é um cartão central de 544 px sobre o fundo escurecido" do
      caixa = retangulo(painel)
      expect(caixa).to include("x" => 428, "largura" => 544, "y" => be_within(0.6).of((900 - caixa["altura"]) / 2))
      expect(estilo(painel, "borderRadius")).to eq("16px")
      expect(estilo(painel, "boxShadow")).to include("rgba(2, 6, 23, 0.35) 0px 24px 70px 0px")
      expect(estilo(painel, "maxHeight")).to eq("852px")
      expect(estilo("[data-controller='painel'] > div[aria-hidden]", "backgroundColor")).to eq("rgba(8, 17, 31, 0.8)")
      print("usuarios-painel-desktop")
    end

    it "tem cabeçalho de 81,5 px com sobretítulo, título e botão de fechar de 36 px" do
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", fechar: "#{painel} > div:first-child button"))
        .to eq(cabecalho: [ 542, 81.5 ], fechar: [ 36, 36 ])
      expect(retangulo("#{painel} > div:first-child button")).to include("x" => 915)
      expect(estilo("#{painel} > div:first-child p", "letterSpacing")).to eq("2.42px")
      expect(estilo("#{painel} h2", "fontSize")).to eq("20px")
    end

    it "tem campos de 44 px separados por 20 px e a nota dos campos requeridos" do
      campos = "#{painel} form > div"
      expect(tamanhos(nome: "#{campos}:nth-of-type(1)", entrada: "#{painel} form input[type='text']", nota: "#{painel} form > p"))
        .to eq(nome: [ 502, 66.8 ], entrada: [ 502, 44 ], nota: [ 502, 16 ])
      expect(retangulo("#{campos}:nth-of-type(2)")["y"] - retangulo("#{campos}:nth-of-type(1)")["y"]).to be_within(0.2).of(86.8)
      expect(estilo("#{painel} form input[type='text']", "borderRadius")).to eq("12px")
      expect(estilo("#{painel} form input[type='text']", "backgroundColor")).to eq("rgb(241, 244, 255)")
      expect(page).to have_css("#{painel} form > p", text: "Os campos marcados com * são requeridos.")
    end

    it "tem rodapé de 71 px com Cancelar e Salvar à direita" do
      rodape = "#{painel} > div:last-child > div:last-child"
      expect(tamanhos(rodape: rodape)).to eq(rodape: [ 542, 71 ])
      expect(retangulo("#{rodape} button[type='button']")).to include("altura" => 38, "largura" => be_within(1).of(92.5))
      salvar = retangulo("#{rodape} button[type='submit']")
      expect(salvar).to include("altura" => 38, "largura" => be_within(1).of(127.7))
      expect(salvar["x"] + salvar["largura"]).to be_within(0.5).of(951)
    end

    it "trava a rolagem da página, põe o foco no primeiro campo e destrava ao fechar no ×" do
      expect(rolagem_travada?).to be(true)
      expect(page.evaluate_script("document.activeElement.name")).to eq("user[nome]")

      click_on "Fechar formulário"

      expect(page).to have_no_css(painel)
      expect(rolagem_travada?).to be(false)
    end

    it "mostra a faixa de erro embutida e o erro embaixo do campo, com o miolo no topo" do
      usar_tela(largura: 1400, altura: 420)
      fill_in "Nome completo *", with: "Ana"
      fill_in "E-mail *", with: "maria@seed.ap.gov.br"
      page.execute_script("document.querySelector(\"[data-painel-target='miolo']\").scrollTop = 500")
      click_on "Salvar usuário"

      expect(page).to have_css("#{painel} [data-faixa-aviso='erro']", text: "Revise os campos destacados")
      expect(page.evaluate_script("document.querySelector(\"[data-painel-target='miolo']\").scrollTop")).to eq(0)
      expect(estilo("#{painel} [data-faixa-aviso='erro']", "borderTopColor")).to eq("rgb(242, 195, 187)")
      expect(estilo("#{painel} [data-faixa-aviso='erro']", "borderRadius")).to eq("14.4px")
      expect(estilo("#{painel} input[type='email']", "borderTopColor")).to eq("rgb(204, 95, 85)")
      expect(estilo("#{painel} #erro_email", "color")).to eq("rgb(139, 53, 45)")
    end
  end

  context "quando o painel de acessos e papéis está aberto" do
    before do
      create(:core_concessao, user: admin, papel: "superadmin")
      visit core_usuarios_path
      usar_tema("light")
      within(linha_maria) { click_on "Permissões" }
      find("#{painel} h2", text: "MARIA OLIVEIRA")
    end

    # Este painel não existe no seed neste formato: confere só a consistência com os outros painéis.
    it "usa o mesmo cartão e os mesmos campos dos outros painéis" do
      expect(retangulo(painel)).to include("x" => 428, "largura" => 544)
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", rodape: "#{painel} > div:last-child > div:last-child"))
        .to eq(cabecalho: [ 542, 81.5 ], rodape: [ 542, 73 ])
      expect(retangulo("#permissao_core select")).to include("altura" => 44)
      expect(estilo("#permissao_core select", "borderRadius")).to eq("12px")
      expect(estilo("#permissao_core select", "paddingLeft")).to eq("16px")
      expect(estilo("#permissao_core label", "fontSize")).to eq("14px")
      expect(retangulo("#permissao_core button[aria-label^='Conceder']")).to include("altura" => 44)
      print("usuarios-acessos-desktop")
    end
  end

  context "quando o diálogo de confirmação está aberto no desktop" do
    before do
      visit core_usuarios_path
      usar_tema("light")
      abrir_confirmacao
    end

    it "é o mesmo cartão central do painel, com 20 px depois da descrição" do
      caixa = retangulo(confirmacao)
      expect(caixa).to include("x" => 428, "largura" => 544, "y" => be_within(0.6).of((900 - caixa["altura"]) / 2))
      expect(estilo(confirmacao, "maxHeight")).to eq("852px")
      expect(tamanhos(cabecalho: "#{confirmacao} > div:nth-child(1)", rodape: "#{confirmacao} > div:nth-child(3)"))
        .to eq(cabecalho: [ 542, 81.5 ], rodape: [ 542, 73 ])
      descricao = retangulo("#confirmacao_descricao")["altura"]
      expect(retangulo("#{confirmacao} > div:nth-child(2)")["altura"]).to be_within(0.2).of(20 + descricao + 20 + 20)
      print("usuarios-confirmacao-desktop")
    end

    it "tem os botões de 40 px, com o de confirmar no tom de perigo" do
      rodape = "#{confirmacao} > div:nth-child(3)"
      expect(retangulo("#{rodape} button[data-confirmacao='cancelar']")).to include("altura" => 40, "largura" => be_within(1).of(93.9))
      confirmar = retangulo("#{rodape} button[data-confirmacao='confirmar']")
      expect(confirmar).to include("altura" => 40, "largura" => be_within(1).of(149.8))
      expect(confirmar["x"] + confirmar["largura"]).to be_within(0.5).of(951)
      expect(estilo("#{rodape} button[data-confirmacao='confirmar']", "backgroundColor")).to eq("rgb(196, 75, 58)")
    end

    it "trava a rolagem da página enquanto está aberto e destrava ao cancelar" do
      expect(rolagem_travada?).to be(true)

      within("#confirmacao") { click_on "Cancelar" }

      expect(page).to have_no_css(confirmacao, visible: :visible)
      expect(rolagem_travada?).to be(false)
    end

    it "usa o tom primário para ativar um usuário" do
      within("#confirmacao") { click_on "Cancelar" }
      within(linha_joao) { click_on "Ativar usuário" }

      expect(page).to have_css("#{confirmacao} h2", text: "Ativar usuário")
      expect(page).to have_css("#{confirmacao} button[data-confirmacao='confirmar'][data-tom='primario']")
      # A cor troca com transição de 160 ms: espera chegar na cor de destaque.
      page.document.synchronize(2, errors: [ Capybara::ExpectationNotMet ]) do
        cor = estilo("#{confirmacao} button[data-confirmacao='confirmar']", "backgroundColor")
        raise Capybara::ExpectationNotMet, "cor do botão: #{cor}" unless cor == "rgb(79, 99, 234)"
      end
    end
  end

  context "quando está no celular" do
    before do
      usar_tela_de_celular
      visit core_usuarios_path
      usar_tema("light")
    end

    it "abre o painel na altura inteira, encostado à direita, com 92% da largura" do
      abrir_painel

      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(estilo(painel, "borderRadius")).to eq("0px")
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", entrada: "#{painel} form input[type='text']"))
        .to eq(cabecalho: [ 357.8, 81.5 ], entrada: [ 317.8, 44 ])
      expect(retangulo("#{painel} > div:first-child button")).to include("x" => 334, "y" => 22.3, "largura" => 36, "altura" => 36)
      rodape = "#{painel} > div:last-child > div:last-child"
      expect(retangulo(rodape)).to include("y" => 729, "altura" => 115)
      expect(tamanhos(cancelar: "#{rodape} button[type='button']", salvar: "#{rodape} button[type='submit']"))
        .to eq(cancelar: [ 317.8, 38 ], salvar: [ 317.8, 36 ])
      expect(sem_rolagem_horizontal?).to be(true)
      print("usuarios-painel-celular")
    end

    it "abre a confirmação no mesmo formato, com os botões empilhados" do
      abrir_confirmacao

      expect(retangulo(confirmacao)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      rodape = "#{confirmacao} > div:nth-child(3)"
      expect(retangulo(rodape)).to include("y" => 723, "altura" => 121)
      expect(tamanhos(cancelar: "#{rodape} button[data-confirmacao='cancelar']", confirmar: "#{rodape} button[data-confirmacao='confirmar']"))
        .to eq(cancelar: [ 317.8, 40 ], confirmar: [ 317.8, 40 ])
      print("usuarios-confirmacao-celular")
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
