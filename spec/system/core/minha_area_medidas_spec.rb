require "rails_helper"

# Medidas do sino, de Notificações, do Perfil e do histórico de Trocar senha conferidas contra o seed
# rodando (notifications-bell.tsx, platform-notifications-module.tsx, my-profile-module.tsx e
# my-password-module.tsx), no desktop (1400 px) e no celular (390 px).
RSpec.describe "Minha área com as medidas do seed", :js do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "12345678901") }

  before { sign_in maria }

  def sino = "#sino_notificacoes"
  def painel_do_sino = "#{sino} [data-dropdown-target='menu']"
  def itens_do_sino = "#{sino} .overflow-y-auto > form"
  def cartao = "main section:has(table)"

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  def notificar(titulo, lida: false, ha: 0.minutes)
    notificacao = Core::Notificacoes::Criar.call(destinatarios: maria, evento: "core.acesso.papel_concedido", titulo: titulo,
                                                 mensagem: "Papel Auditor no módulo Administração.", ator: nil).first
    notificacao.update!(created_at: ha.ago, lida_em: (Time.current if lida))
    notificacao
  end

  # Posição de um elemento em relação ao canto de outro (para não depender do que vem antes na página).
  def relativo(seletor, base)
    alvo = retangulo(seletor)
    origem = retangulo(base)
    alvo.merge("x" => (alvo["x"] - origem["x"]).round(1), "y" => (alvo["y"] - origem["y"]).round(1))
  end

  describe "sino do topo" do
    context "quando está no desktop" do
      before do
        notificar("Papel antigo", lida: true, ha: 2.hours)
        notificar("Papel novo")
        visit root_path
        usar_tema("light")
      end

      it "fica entre o tema e o avatar, com 40 px e o contador de não lidas" do
        expect(retangulo("header button[aria-label='Alternar tema']")).to include("x" => 1240, "y" => 12)
        expect(retangulo("#{sino} > button")).to include("x" => 1288, "y" => 12, "largura" => 40, "altura" => 40)
        expect(retangulo("header button[aria-label='Abrir menu da conta']")).to include("x" => 1336, "y" => 12)
        expect(tamanhos(icone: "#{sino} > button svg")).to eq(icone: [ 18, 18 ])
        expect(page).to have_css("#{sino} [data-sino-contador]", text: "1")
        expect(estilo("#{sino} [data-sino-contador]", "fontSize")).to eq("10px")
        expect(estilo("#{sino} [data-sino-contador]", "backgroundColor")).to eq("rgb(79, 99, 234)")
      end

      it "abre um painel de 384 px com cabeçalho, itens e rodapé como no seed" do
        find("#{sino} > button").click

        expect(retangulo(painel_do_sino)).to include("x" => 944, "y" => 64, "largura" => 384)
        expect(estilo(painel_do_sino, "borderRadius")).to eq("12px")
        expect(tamanhos(cabecalho: "#{painel_do_sino} > div:nth-child(1)", item: "#{itens_do_sino}:nth-of-type(1)",
                        rodape: "#{painel_do_sino} > div:nth-child(3)"))
          .to eq(cabecalho: [ 382, 61 ], item: [ 382, 93 ], rodape: [ 382, 47.8 ])
        expect(estilo("#{painel_do_sino} .overflow-y-auto", "maxHeight")).to eq("416px")
        expect(retangulo("#{painel_do_sino} > div:nth-child(3) a")).to include("x" => 961)
        expect(page).to have_link("Ver todas as notificações", href: "/minha-area/notificacoes")
        print("sino-desktop")
      end

      it "destaca a notificação não lida com o fundo do seed" do
        find("#{sino} > button").click

        # --accent-soft (alfa 0,18) com o /40 do seed = alfa 0,072
        expect(estilo("#{itens_do_sino}:nth-of-type(1) button", "backgroundColor")).to match(%r{/ 0\.07})
        expect(estilo("#{itens_do_sino}:nth-of-type(2) button", "backgroundColor")).to eq("rgb(255, 255, 255)")
        expect(estilo("#{itens_do_sino}:nth-of-type(1) button", "paddingLeft")).to eq("16px")
        expect(estilo("#{itens_do_sino}:nth-of-type(1) button span", "fontWeight")).to eq("600")
      end
    end

    it "mostra só as 6 mais recentes e a mensagem de vazio quando não há nenhuma" do
      visit root_path
      find("#{sino} > button").click
      expect(page).to have_css("#{painel_do_sino} .overflow-y-auto > div", text: "Nenhuma notificação no momento.")
      expect(page).to have_no_css("#{sino} [data-sino-contador]")

      7.times { |i| notificar("Aviso #{i}", ha: i.minutes) }
      visit root_path
      find("#{sino} > button").click

      expect(page).to have_css(itens_do_sino, count: 6)
    end
  end

  describe "tela de notificações" do
    before do
      notificar("Papel antigo", lida: true, ha: 2.hours)
      notificar("Papel novo")
    end

    context "quando está no desktop" do
      before do
        visit notificacoes_path
        usar_tema("light")
      end

      it "tem a busca e os dois botões nas colunas do seed" do
        expect(relativo("#{cartao} form", cartao)).to include("x" => 1, "y" => 1, "largura" => 1082, "altura" => 107.8)
        expect(relativo("#{cartao} input[name='q']", cartao)).to include("x" => 25, "y" => 43.8, "largura" => 914, "altura" => 44)
        expect(relativo("#{cartao} button[aria-label='Filtrar notificações']", cartao)).to include("x" => 955, "y" => 43.8, "largura" => 44)
        expect(relativo("#{cartao} a[aria-label='Limpar busca']", cartao)).to include("x" => 1015, "y" => 43.8, "largura" => 44)
      end

      it "tem a faixa Caixa de notificações, o resumo e a tabela nas alturas do seed" do
        lista = "#notificacoes_lista"
        expect(relativo("#{lista} > div:nth-child(1)", cartao)).to include("x" => 1, "y" => 108.8, "largura" => 1082, "altura" => 73)
        marcar = retangulo("#{lista} > div:nth-child(1) button")
        expect(marcar).to include("altura" => 38, "largura" => be_within(1).of(182.1))
        expect(marcar["x"] + marcar["largura"]).to be_within(0.5).of(1343)
        expect(relativo("#{lista} > div:nth-child(2)", cartao)).to include("y" => 181.8, "altura" => 53)
        expect(relativo("#{cartao} table thead th", cartao)).to include("y" => 234.8, "altura" => 55.1)
        expect(tamanhos(selo: "#{cartao} tbody tr td:nth-child(6) span", botao: "#{cartao} tbody tr td:nth-child(7) button").transform_values(&:last))
          .to eq(selo: 24, botao: 36)
        print("notificacoes-desktop")
      end

      it "destaca a linha não lida com o fundo do seed" do
        # --accent-soft (alfa 0,18) com o /20 do seed = alfa 0,036
        expect(estilo("#{cartao} tbody tr:nth-child(1)", "backgroundColor")).to match(%r{/ 0\.03})
        expect(estilo("#{cartao} tbody tr:nth-child(2)", "backgroundColor")).to eq("rgba(0, 0, 0, 0)")
        expect(estilo("#{cartao} tbody tr td:nth-child(6) span", "backgroundColor")).to eq("rgb(245, 247, 251)")
      end
    end

    context "quando está no celular" do
      before do
        usar_tela_de_celular
        visit notificacoes_path
        usar_tema("light")
      end

      it "empilha a busca e os botões e rola a tabela dentro do cartão" do
        filtrar = relativo("#{cartao} button[aria-label='Filtrar notificações']", cartao)
        limpar = relativo("#{cartao} a[aria-label='Limpar busca']", cartao)
        expect(relativo("#{cartao} input[name='q']", cartao)).to include("x" => 25, "largura" => 308, "altura" => 44)
        expect(filtrar).to include("x" => 25, "largura" => 44, "altura" => 44)
        expect(limpar).to include("x" => 25, "y" => filtrar["y"] + 44 + 16)
        expect(retangulo("#{cartao} .overflow-x-auto")).to include("x" => 17, "largura" => 356)
        expect(sem_rolagem_horizontal?).to be(true)
        print("notificacoes-celular")
      end

      it "mostra o cartão de avisos do aparelho com o texto na linha inteira e o botão embaixo" do
        texto = retangulo("[data-controller='push'] h2")
        expect(texto).to include("x" => 41, "largura" => 308)
        botao = retangulo("[data-controller='push'] button:not([hidden])")
        expect(botao["y"]).to be > texto["y"] + texto["altura"]
        expect(botao["x"] + botao["largura"]).to be <= 349
      end

      it "abre o painel do sino dentro da tela" do
        find("#{sino} > button").click

        expect(retangulo(painel_do_sino)).to include("x" => 12, "largura" => 366)
        print("sino-celular")
      end
    end
  end

  describe "tela de perfil" do
    context "quando está no desktop" do
      before do
        visit meu_perfil_path
        usar_tema("light")
      end

      it "tem o cartão, o avatar de 64 px e o formulário de imagem nas posições do seed" do
        expect(retangulo("main section + div > section")).to include("x" => 284, "y" => 153, "largura" => 1084)
        expect(tamanhos(cabecalho: "main section + div > section > div:nth-child(1)")).to eq(cabecalho: [ 1082, 85 ])
        expect(retangulo("main .rounded-full")).to include("x" => 309, "y" => 259, "largura" => 64, "altura" => 64)
        expect(tamanhos(icone: "main .rounded-full svg")).to eq(icone: [ 24, 24 ])
        expect(retangulo("main input[type='file']")).to include("x" => 389, "y" => 268, "altura" => 46)
        expect(retangulo("main form button[type='submit']")).to include("y" => 271, "altura" => 40, "largura" => be_within(1).of(132.8))
        print("perfil-desktop")
      end

      it "deixa o botão Trocar imagem apagado até escolher um arquivo" do
        expect(estilo("main form button[type='submit']", "opacity")).to eq("0.7")

        attach_file "Nova imagem do perfil", Rails.root.join("spec/fixtures/files/avatar.png")

        expect(page).to have_css("main form:not(:has(:invalid))")
        page.document.synchronize(2, errors: [ Capybara::ExpectationNotMet ]) do
          opacidade = estilo("main form button[type='submit']", "opacity")
          raise Capybara::ExpectationNotMet, "opacidade: #{opacidade}" unless opacidade == "1"
        end
      end

      it "tem os campos em duas colunas de 509 px com 66 px de altura" do
        expect(retangulo("main dl")).to include("x" => 309, "y" => 347, "largura" => 1034)
        expect(retangulo("main dl > div:nth-child(1)")).to eq("x" => 309, "y" => 347, "largura" => 509, "altura" => 66)
        expect(retangulo("main dl > div:nth-child(2)")).to eq("x" => 834, "y" => 347, "largura" => 509, "altura" => 66)
        expect(retangulo("main dl > div:nth-child(3)")).to include("x" => 309, "y" => 429)
        expect(estilo("main dl dt", "letterSpacing")).to eq("1.44px")
        expect(estilo("main dl > div", "backgroundColor")).to eq("rgb(245, 247, 251)")
        expect(estilo("main dl > div", "borderRadius")).to eq("12px")
      end
    end

    context "quando está no celular" do
      before do
        usar_tela_de_celular
        visit meu_perfil_path
      end

      it "empilha o avatar, o formulário e os campos" do
        expect(retangulo("main .rounded-full")).to include("x" => 41, "y" => 259, "largura" => 64)
        expect(retangulo("main input[type='file']")).to include("x" => 41, "y" => 339, "altura" => 46)
        expect(retangulo("main form button[type='submit']")).to include("x" => 41, "y" => 397, "altura" => 40)
        expect(retangulo("main dl > div:nth-child(1)")).to eq("x" => 41, "y" => 461, "largura" => 308, "altura" => 66)
        expect(retangulo("main dl > div:nth-child(2)")).to include("x" => 41, "y" => 543)
        expect(sem_rolagem_horizontal?).to be(true)
        print("perfil-celular")
      end
    end

    it "mostra a faixa de erro 24 px abaixo do cabeçalho de página e 24 px acima do cartão" do
      visit meu_perfil_path
      page.execute_script("document.querySelector(\"main input[type='file']\").required = false")
      click_on "Trocar imagem"

      expect(page).to have_css("[data-faixa-aviso='erro']")
      faixa = retangulo("[data-faixa-aviso='erro']")
      expect(faixa).to include("x" => 284, "y" => 153, "largura" => 1084)
      expect(retangulo("main section + div > section")["y"]).to eq(faixa["y"] + faixa["altura"] + 24)
    end
  end

  describe "histórico de trocas de senha" do
    def historico = "main section + div > section:last-child"

    it "é um segundo cartão, 24 px abaixo do primeiro, com a tabela do seed" do
      visit edit_minha_senha_path
      usar_tema("light")

      formulario = retangulo("main section + div > section:first-child")
      expect(retangulo(historico)).to include("x" => 284, "largura" => 1084, "y" => (formulario["y"] + formulario["altura"] + 24).round(1))
      expect(tamanhos(cabecalho: "#{historico} > div:first-child", th: "#{historico} thead th").transform_values(&:last))
        .to eq(cabecalho: 61, th: 55.1)
      # Linha vazia como no seed: a regra da tabela vence as classes do td (55,2 px, texto à esquerda).
      expect(tamanhos(vazio: "#{historico} tbody td")).to eq(vazio: [ 1082, 55.2 ])
      expect(estilo("#{historico} tbody td", "textAlign")).to eq("left")
      print("senha-historico-desktop")
    end

    it "rola a tabela dentro do cartão no celular" do
      usar_tela_de_celular
      visit edit_minha_senha_path

      expect(retangulo("#{historico} .overflow-x-auto")).to include("x" => 17, "largura" => 356)
      expect(retangulo("#{historico} table")).to include("largura" => 780)
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end
end
