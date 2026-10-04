require "rails_helper"

# Campo de busca (autocomplete), conferido contra o AutocompleteSearchField do seed
# (/hr/assignments → Nova lotação): campo de 44 px, lista 8 px abaixo, raio 12, itens px-4 py-3.
RSpec.describe "Campo de busca (autocomplete)", :js do
  let(:admin) do
    create(:user, nome: "ADMIN DA SILVA").tap do |u|
      create(:core_concessao, user: u, modulo: "rh", papel: "admin")
      create(:core_concessao, user: u, papel: "superadmin")
    end
  end

  before do
    Rh::Tabelas.garantir_padroes
    12.times { |i| create(:rh_unidade, nome: "Unidade de teste #{i}", sigla: "UT#{i}") }
    12.times { |i| create(:rh_cargo, nome: "Cargo de teste #{i}") }
    create(:rh_funcao, nome: "Técnico")
    create(:rh_pessoa, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    sign_in admin
  end

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  def miolo = "[data-painel-target='miolo']"
  def base(seletor) = retangulo(seletor).then { |r| r["y"] + r["altura"] }

  # A lista inteira aparece na parte visível do miolo do painel (acima do rodapé).
  def lista_visivel_no_painel?(lista)
    retangulo(lista)["y"] >= retangulo(miolo)["y"] && base(lista) <= base(miolo) + 0.5
  end

  describe "no painel Nova lotação" do
    before do
      visit new_rh_lotacao_path
      usar_tema("light")
    end

    it "tem o campo, a lista e os itens nas medidas do seed" do
      fill_in "Pessoa *", with: "mar"
      expect(page).to have_css("#lotacao_pessoa_lista [role='option']", text: "MARIA OLIVEIRA")

      campo = retangulo("#lotacao_pessoa")
      expect(campo).to include("x" => 449, "largura" => 502, "altura" => 44)
      expect(retangulo("#lotacao_pessoa_lista")).to include("x" => 449, "largura" => 502, "y" => campo["y"] + 44 + 8)
      expect(estilo("#lotacao_pessoa_lista", "borderRadius")).to eq("12px")
      expect(estilo("#lotacao_pessoa_lista", "backgroundColor")).to eq("rgb(255, 255, 255)")
      opcao = "#lotacao_pessoa_lista [role='option']"
      expect(retangulo(opcao)).to include("x" => 450, "largura" => 500)
      expect([ estilo(opcao, "paddingLeft"), estilo(opcao, "paddingTop"), estilo(opcao, "fontSize") ]).to eq(%w[16px 12px 14px])
      print("autocomplete-lotacao")
    end

    it "segue a ordem do painel do seed: Pessoa, Unidade, Função, Início e os botões do rodapé" do
      expect(all("#formulario_lotacao label").map(&:text)).to eq([ "Pessoa *", "Unidade *", "Função *", "Início *" ])
      expect(page).to have_css("[role='dialog'] h2", text: "Conceder lotação")
      expect(page).to have_button("Cancelar").and have_button("Salvar lotação")
      expect(tamanhos(pessoa: "#lotacao_pessoa", unidade: "#lotacao_unidade", funcao: "#lotacao_funcao", inicio: "#lotacao_data_inicio"))
        .to eq(pessoa: [ 502, 44 ], unidade: [ 502, 44 ], funcao: [ 502, 44 ], inicio: [ 502, 44 ])
    end

    it "é um combobox com lista de opções e funciona só com o teclado" do
      campo = find("#lotacao_unidade")
      expect(campo[:role]).to eq("combobox")
      expect(campo["aria-controls"]).to eq("lotacao_unidade_lista")
      expect(campo["aria-expanded"]).to eq("false")

      campo.send_keys("teste 11")
      expect(page).to have_css("#lotacao_unidade_lista[role='listbox'] [role='option']", count: 1)
      expect(page).to have_css("#lotacao_unidade_opcao_0", text: "UT11 - UNIDADE DE TESTE 11")
      expect(campo["aria-expanded"]).to eq("true")
      expect(page).to have_no_css("#lotacao_unidade_lista [role='option']:not([tabindex='-1'])")

      campo.send_keys(:arrow_down)
      expect(page).to have_css("#lotacao_unidade_lista [role='option'][aria-selected='true']", count: 1)
      expect(campo["aria-activedescendant"]).to eq("lotacao_unidade_opcao_0")
      # O destaque entra com transição de 160 ms: espera o filete aparecer.
      page.document.synchronize(2, errors: [ Capybara::ExpectationNotMet ]) do
        sombra = estilo("#lotacao_unidade_opcao_0", "boxShadow")
        raise Capybara::ExpectationNotMet, "sombra: #{sombra}" unless sombra.include?("3px 0px 0px 0px inset")
      end

      primeira = find("#lotacao_unidade_opcao_0").text
      campo.send_keys(:enter)
      expect(page).to have_no_css("#lotacao_unidade_lista", visible: :visible)
      expect(campo.value).to eq(primeira)
      expect(find("#lotacao_unidade_valor", visible: :hidden).value).to be_present
      expect(campo["aria-expanded"]).to eq("false")
    end

    it "não escolhe da lista antiga se o Enter vier antes de a busca voltar" do
      campo = find("#lotacao_unidade")
      campo.click
      expect(page).to have_css("#lotacao_unidade_lista [role='option']", count: 12)

      campo.send_keys("teste 11", :arrow_down, :enter)

      expect(page).to have_css("#lotacao_unidade_lista [role='option']", count: 1)
      expect(campo.value).to eq("teste 11")
      expect(find("#lotacao_unidade_valor", visible: :hidden).value).to be_blank
    end

    it "fecha a lista com Esc e ao sair do campo com Tab, indo direto para o próximo campo" do
      campo = find("#lotacao_unidade")
      campo.click
      expect(page).to have_css("#lotacao_unidade_lista [role='option']")
      campo.send_keys(:escape)
      expect(page).to have_no_css("#lotacao_unidade_lista", visible: :visible)

      campo.send_keys(:arrow_down)
      expect(page).to have_css("#lotacao_unidade_lista [role='option']")
      campo.send_keys(:tab)

      expect(page).to have_no_css("#lotacao_unidade_lista", visible: :visible)
      expect(page.evaluate_script("document.activeElement.id")).to eq("lotacao_funcao")
    end
  end

  describe "no painel de pessoa" do
    it "tem Vínculo e Cargo um por linha e rola o painel para mostrar a lista aberta" do
      visit new_rh_pessoa_path
      usar_tema("light")

      expect(tamanhos(vinculo: "#pessoa_vinculo_tipo_vinculo", cargo: "#pessoa_vinculo_cargo"))
        .to eq(vinculo: [ 468, 44 ], cargo: [ 468, 44 ])
      find("#pessoa_vinculo_cargo").click

      expect(page).to have_css("#pessoa_vinculo_cargo_lista [role='option']", minimum: 8)
      expect(lista_visivel_no_painel?("#pessoa_vinculo_cargo_lista")).to be(true)
      print("autocomplete-pessoa")
    end

    it "no celular também mostra a lista inteira dentro do painel, sem rolagem horizontal" do
      usar_tela_de_celular
      visit new_rh_pessoa_path

      find("#pessoa_vinculo_cargo").click

      expect(page).to have_css("#pessoa_vinculo_cargo_lista [role='option']", minimum: 8)
      expect(lista_visivel_no_painel?("#pessoa_vinculo_cargo_lista")).to be(true)
      expect(retangulo("#pessoa_vinculo_cargo")).to include("largura" => 283.8, "altura" => 44)
      # O texto de ajuda cabe no campo, sem corte.
      expect(page.evaluate_script("(() => { const c = document.getElementById('pessoa_vinculo_cargo'); return c.scrollWidth <= c.clientWidth })()")).to be(true)
      expect(sem_rolagem_horizontal?).to be(true)
      print("autocomplete-pessoa-celular")
    end
  end

  describe "no painel de unidade" do
    it "mostra a dica da unidade superior embaixo do campo, sem cortar o texto de ajuda" do
      visit new_rh_unidade_path

      expect(find("#unidade_pai")[:placeholder]).to eq("Digite 3 letras para procurar")
      expect(page).to have_css("#unidade_pai_lista ~ p, div:has(> #unidade_pai) ~ p", text: "Em branco = unidade de primeiro nível.")
    end

    it "põe os campos do endereço lado a lado no desktop e empilhados no celular" do
      visit new_rh_unidade_path
      rua = retangulo("#unidade_dados_escola_logradouro")
      numero = retangulo("#unidade_dados_escola_numero")
      expect(numero).to include("y" => rua["y"], "altura" => 44, "largura" => 128)
      expect(numero["x"]).to be > rua["x"] + rua["largura"]

      usar_tela_de_celular
      visit new_rh_unidade_path
      rua = retangulo("#unidade_dados_escola_logradouro")
      numero = retangulo("#unidade_dados_escola_numero")
      expect(numero).to include("x" => rua["x"], "largura" => rua["largura"], "altura" => 44)
      expect(numero["y"]).to be > rua["y"] + 44
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end

  describe "no filtro Evento da Auditoria" do
    def conferir_lista_flutuante
      tabela_antes = retangulo("main table")["y"]
      find("#evento").click
      expect(page).to have_css("#evento_lista [role='option']", minimum: 9)

      expect(estilo("#evento_lista", "position")).to eq("absolute")
      expect(retangulo("main table")["y"]).to eq(tabela_antes)
      lista = retangulo("#evento_lista")
      # Nada do cartão corta a lista: o ponto mais baixo dela continua sendo a própria lista.
      dentro = page.evaluate_script("document.getElementById('evento_lista').contains(document.elementFromPoint(#{lista['x'] + 20}, #{lista['y'] + lista['altura'] - 6}))")
      expect(dentro).to be(true)
      expect(lista["x"] + lista["largura"]).to be <= largura_da_tela
    end

    it "abre a lista por cima da tabela, sem empurrar nem ser cortada" do
      visit core_auditoria_path
      usar_tema("light")

      conferir_lista_flutuante
      expect(find("#evento")[:placeholder]).to eq("Todos · digite 3 letras")
      expect(page.evaluate_script("(() => { const c = document.getElementById('evento'); return c.scrollWidth <= c.clientWidth })()")).to be(true)
      print("autocomplete-auditoria")
    end

    it "no celular também" do
      usar_tela_de_celular
      visit core_auditoria_path

      conferir_lista_flutuante
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end
end
