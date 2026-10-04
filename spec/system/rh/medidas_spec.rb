require "rails_helper"

# Medidas e textos do RH conferidos contra o seed rodando (/hr/employment-types, /hr/units, /hr/people,
# /hr/assignments, /hr/permissions; hr-*-module.tsx e admin-shell.tsx), em 1400 px e 390 px.
RSpec.describe "RH com as medidas do seed", :js do
  let(:admin) { create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") } }
  let!(:unidade) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let!(:pessoa) { create(:rh_pessoa, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  before do
    Rh::Tabelas.garantir_padroes
    sign_in admin
  end

  def painel = "[role='dialog']"
  def cartao = "main section + section"

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  def titulos_do_painel
    [ find("#{painel} > div:first-child p").text(:all).strip.downcase, find("#{painel} h2").text ]
  end

  describe "listagem de uma tabela de referência" do
    it "tem o cabeçalho, os filtros, o resumo e a tabela nas medidas do seed" do
      visit rh_tipos_vinculo_path
      usar_tema("light")

      expect(retangulo("main section a[title='Novo vínculo']")).to include("y" => 76, "altura" => 40, "largura" => be_within(1).of(142.5))
      expect(retangulo("#{cartao} form")).to include("x" => 285, "y" => 154, "largura" => 1082, "altura" => 107.8)
      expect(retangulo("#{cartao} input[name='q']")).to include("x" => 309, "y" => 196.8, "largura" => 639.5, "altura" => 44)
      expect(retangulo("#{cartao} select[name='status']")).to include("x" => 964.5, "largura" => 266.5, "altura" => 44)
      expect(retangulo("#tabela_lista > div:first-child")).to include("y" => 261.8, "altura" => 53)
      expect(retangulo("#{cartao} thead th")).to include("y" => 314.8, "altura" => 55.1)
      expect(tamanhos(selo: "#{cartao} tbody td span", editar: "#{cartao} tbody td:last-child a")).to eq(selo: [ 50.1, 24 ], editar: [ 36, 36 ])
    end
  end

  describe "painéis de formulário" do
    it "usam o sobretítulo e o título do seed (Novo X / Cadastrar X, Editar X / Atualizar X)" do
      visit new_rh_tipo_vinculo_path
      expect(titulos_do_painel).to eq([ "novo vínculo", "Cadastrar vínculo" ])

      visit new_rh_unidade_path
      expect(titulos_do_painel).to eq([ "nova unidade", "Cadastrar unidade" ])
      visit edit_rh_unidade_path(unidade)
      expect(titulos_do_painel).to eq([ "editar unidade", "Atualizar unidade" ])

      visit new_rh_pessoa_path
      expect(titulos_do_painel).to eq([ "nova pessoa", "Cadastrar pessoa" ])
      expect(page).to have_button("Cadastrar pessoa")
      visit edit_rh_pessoa_path(pessoa)
      expect(titulos_do_painel).to eq([ "editar pessoa", "Atualizar pessoa" ])
      expect(page).to have_button("Salvar pessoa")

      visit new_rh_pessoa_lotacao_path(pessoa)
      expect(titulos_do_painel).to eq([ "nova lotação", "Conceder lotação" ])

      visit edit_rh_permissao_path(admin)
      expect(titulos_do_painel).to eq([ "editar permissão", "Atualizar permissão do RH" ])
    end

    it "o painel de unidade tem um campo por linha, com 44 px, e o bloco da escola sem folga dupla" do
      visit new_rh_unidade_path
      usar_tema("light")

      expect(tamanhos(nome: "#unidade_nome", sigla: "#unidade_sigla", tipo: "#unidade_tipo_unidade_id", superior: "#unidade_pai"))
        .to eq(nome: [ 502, 44 ], sigla: [ 502, 44 ], tipo: [ 502, 44 ], superior: [ 502, 44 ])
      expect(retangulo("#unidade_tipo_unidade_id")["y"] - retangulo("#unidade_sigla")["y"]).to be_within(0.2).of(86.8)
      legenda = retangulo("#{painel} fieldset legend")
      expect(retangulo("#{painel} fieldset > p")["y"]).to be_within(0.2).of(legenda["y"] + legenda["altura"] + 16)
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", rodape: "#{painel} > div:last-child > div:last-child"))
        .to eq(cabecalho: [ 542, 81.5 ], rodape: [ 542, 71 ])
      print("rh-unidade-painel")
    end

    it "o painel de pessoa ocupa a altura inteira no celular, sem rolagem horizontal" do
      usar_tela_de_celular
      visit new_rh_pessoa_path

      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(tamanhos(nome: "#pessoa_nome", celular: "#pessoa_celular", cpf: "#pessoa_cpf"))
        .to eq(nome: [ 317.8, 44 ], celular: [ 317.8, 44 ], cpf: [ 317.8, 44 ])
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end

  describe "permissões do RH" do
    it "mostra a permissão num selo neutro, como no seed" do
      visit rh_permissoes_path
      usar_tema("light")

      selo = "#permissao_user_#{admin.id} td:nth-child(3) span"
      expect(page).to have_css(selo, text: "Administrador")
      expect(estilo(selo, "backgroundColor")).to eq("rgb(245, 247, 251)")
      expect(estilo(selo, "color")).to eq("rgb(91, 102, 117)")
      expect(tamanhos(selo: selo)[:selo].last).to eq(24)
    end
  end

  describe "ficha da pessoa" do
    it "tem os cartões separados por 24 px e a grade de detalhes em duas colunas de 66 px" do
      visit rh_pessoa_path(pessoa)
      usar_tema("light")

      expect(retangulo("main section + div > section:nth-child(1)")).to include("x" => 284, "y" => 153, "largura" => 1084)
      primeiro = retangulo("main section + div > section:nth-child(1)")
      expect(retangulo("main section + div > section:nth-child(2)")["y"]).to be_within(0.2).of(primeiro["y"] + primeiro["altura"] + 24)
      expect(retangulo("main dl > div:nth-child(1)")).to include("x" => 309, "largura" => 509, "altura" => 66)
      expect(retangulo("main dl > div:nth-child(2)")).to include("x" => 834, "largura" => 509, "altura" => 66)
      expect(estilo("main dl dt", "letterSpacing")).to eq("1.44px")
    end

    it "no celular empilha os detalhes e mostra as ações do cabeçalho só com ícone" do
      usar_tela_de_celular
      visit rh_pessoa_path(pessoa)

      expect(retangulo("main dl > div:nth-child(1)")).to include("x" => 41, "largura" => 308, "altura" => 66)
      expect(retangulo("main dl > div:nth-child(2)")).to include("x" => 41)
      expect(tamanhos(voltar: "main section a[title='Voltar']", editar: "main section a[title='Editar pessoa']"))
        .to eq(voltar: [ 36, 36 ], editar: [ 36, 36 ])
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end
end
