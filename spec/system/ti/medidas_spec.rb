require "rails_helper"

# Medidas e textos da TI conferidos contra o seed rodando (/helpdesk/request-categories, /helpdesk/opening-profiles,
# /helpdesk/technical-groups, /helpdesk/solicitations, /helpdesk/user-accesses, /helpdesk/tickets, /helpdesk/operation;
# helpdesk-*-module.tsx e helpdesk-ticket-detail.tsx), em 1400 px e 390 px.
RSpec.describe "TI com as medidas do seed", :js do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }
  let!(:categoria) { create(:ti_categoria, nome: "Rede", descricao: "Demandas de rede e conectividade.") }
  let!(:grupo) { create(:ti_grupo_tecnico, nome: "Infraestrutura", descricao: "Atendimento de infraestrutura.") }
  let!(:perfil) { create(:ti_perfil_abertura, nome: "Gestor escolar", descricao: "Gestores das escolas.") }
  let!(:solicitacao) { create(:ti_problema, nome: "Sem internet", descricao: "A unidade está sem internet.", categoria: categoria) }

  before { sign_in admin }

  def painel = "[role='dialog']"
  def cartao = "main section + section"

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  def titulos_do_painel
    [ find("#{painel} > div:first-child p").text(:all).strip.downcase, find("#{painel} h2").text ]
  end

  describe "listagens da administração" do
    it "categorias: cabeçalho, filtros, resumo e a linha de duas linhas (nome + descrição) nas medidas do seed" do
      visit ti_categorias_path
      usar_tema("light")

      expect(retangulo("main section a[title='Nova categoria']")).to include("y" => 76, "altura" => 40, "largura" => be_within(1).of(157.4))
      expect(retangulo("#{cartao} form")).to include("x" => 285, "y" => 154, "largura" => 1082, "altura" => 107.8)
      expect(retangulo("#catalogo_lista > div:first-child")).to include("y" => 261.8, "altura" => 53)
      expect(retangulo("#{cartao} thead th")).to include("y" => 314.8, "altura" => 55.1)
      # No seed a linha tem 83 px; aqui é a última da tabela, sem a borda de 1 px.
      expect(retangulo("#{cartao} tbody tr")).to include("y" => 369.9, "altura" => 82)
      expect([ estilo("#{cartao} tbody td p", "fontSize"), estilo("#{cartao} tbody td p", "fontWeight") ]).to eq([ "15.2px", "600" ])
      expect(estilo("#{cartao} tbody td p + p", "fontSize")).to eq("14px")
      expect(page).to have_content("1 categoria(s) registrada(s)")
      print("ti-categorias")
    end

    it "grupos técnicos: nome em 15,2 px, selo de autoatribuição e ações na ordem do seed" do
      visit ti_grupos_tecnicos_path
      usar_tema("light")

      expect(retangulo("main section a[title='Novo grupo']")).to include("y" => 76, "altura" => 40, "largura" => be_within(1).of(134))
      expect(page).to have_content("1 grupo(s) técnico(s) registrado(s)")
      expect(all("#{cartao} thead th").map(&:text)).to eq([ "Nome", "Descrição", "Autoatribuição", "Membros", "Solicitações", "Status", "Ações" ])
      # 72,2 no seed, menos a borda da última linha; 47 px abaixo do seed por causa das abas Grupos/Técnicos (pedido do Josue, 2026-10-16)
      expect(retangulo("#{cartao} tbody tr")).to include("y" => 416.9, "altura" => 71.2)
      expect([ estilo("#{cartao} tbody td", "fontSize"), estilo("#{cartao} tbody td", "fontWeight") ]).to eq([ "15.2px", "600" ])
      selo = "#{cartao} tbody td:nth-child(3) span"
      expect(page).to have_css(selo, text: "Permitida")
      expect([ estilo(selo, "backgroundColor"), estilo(selo, "color") ]).to eq([ "rgb(232, 240, 255)", "rgb(49, 92, 207)" ])
      expect(all("#{cartao} tbody td:last-child [title]").map { |botao| botao[:title] })
        .to eq([ "Gerenciar membros", "Gerenciar solicitações", "Editar grupo técnico", "Desativar grupo técnico" ])
      print("ti-grupos")
    end

    it "perfis, solicitações e permissões usam os textos do seed" do
      visit ti_perfis_abertura_path
      expect(page).to have_link("Novo perfil").and have_content("1 perfil(is) de abertura registrado(s)")
      expect(page).to have_css("#{cartao} tbody td:last-child [title='Editar perfil']")

      visit ti_solicitacoes_path
      usar_tema("light")
      expect(all("#{cartao} thead th").map(&:text)).to eq([ "Solicitação", "Categoria", "Perfis de abertura", "Grupos técnicos", "Campos", "Status", "Ações" ])
      expect(page).to have_content("Sem perfis").and have_content("Sem grupos").and have_content("0 campo(s)")
      expect([ estilo("#{cartao} tbody td p", "fontSize"), estilo("#{cartao} tbody td p + p", "fontSize") ]).to eq([ "15.2px", "14px" ])
      print("ti-solicitacoes")

      visit ti_permissoes_path
      expect(page).to have_content("1 usuário(s) encontrado(s)")
    end
  end

  describe "painéis de formulário" do
    it "usam o sobretítulo, o título e o botão do seed" do
      visit new_ti_categoria_path
      expect(titulos_do_painel).to eq([ "categorias de solicitação", "Nova categoria" ])
      expect(page).to have_button("Salvar categoria")
      visit edit_ti_categoria_path(categoria)
      expect(titulos_do_painel).to eq([ "categorias de solicitação", "Editar categoria" ])
      expect(page).to have_button("Salvar alterações")

      visit new_ti_perfil_abertura_path
      expect(titulos_do_painel).to eq([ "novo perfil", "Cadastrar perfil de abertura" ])
      expect(page).to have_button("Salvar perfil")
      visit edit_ti_perfil_abertura_path(perfil)
      expect(titulos_do_painel).to eq([ "editar perfil", "Atualizar perfil de abertura" ])

      visit new_ti_grupo_tecnico_path
      expect(titulos_do_painel).to eq([ "novo grupo", "Cadastrar grupo técnico" ])
      visit edit_ti_grupo_tecnico_path(grupo)
      expect(titulos_do_painel).to eq([ "editar grupo", "Atualizar grupo técnico" ])

      visit new_ti_solicitacao_path
      expect(titulos_do_painel).to eq([ "solicitações", "Nova solicitação" ])
      visit edit_ti_solicitacao_path(solicitacao)
      expect(titulos_do_painel).to eq([ "solicitações", "Editar solicitação" ])
      expect(page).to have_button("Salvar alterações")

      visit new_ti_solicitacao_campo_path(solicitacao)
      expect(titulos_do_painel).to eq([ "campos da solicitação", "Novo campo" ])
    end

    it "o painel de grupo técnico tem os campos do seed: nome 44 px, descrição 112 px e a chave de autoatribuição" do
      visit new_ti_grupo_tecnico_path
      usar_tema("light")

      chave = "#{painel} label:has(#registro_permite_autoatribuicao)"
      expect(tamanhos(nome: "#registro_nome", descricao: "#registro_descricao", chave: chave))
        .to eq(nome: [ 502, 44 ], descricao: [ 502, 112 ], chave: [ 502, 44 ])
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", rodape: "#{painel} > div:last-child > div:last-child"))
        .to eq(cabecalho: [ 542, 81.5 ], rodape: [ 542, 71 ])
      expect(retangulo("#registro_descricao")["y"] - retangulo("#registro_nome")["y"]).to be_within(0.2).of(86.9)

      expect(page).to have_css(chave, text: "Autoatribuição ligada")
      expect(estilo(chave, "backgroundColor")).to eq("rgb(237, 242, 255)")
      find(chave).click
      expect(page).to have_css(chave, text: "Autoatribuição desligada")
      expect(page).to have_unchecked_field("registro_permite_autoatribuicao", visible: :all)
      expect(page).to have_no_content("fila")
      print("ti-grupo-painel")
    end

    it "o resumo da solicitação é uma área de texto de 112 px" do
      visit new_ti_solicitacao_path
      expect(tamanhos(nome: "#solicitacao_nome", resumo: "#solicitacao_descricao")).to eq(nome: [ 502, 44 ], resumo: [ 502, 112 ])
    end
  end

  describe "no celular (390 px)" do
    before { usar_tela_de_celular }

    it "as listas rolam dentro do cartão e a ação do cabeçalho fica só com o ícone" do
      [ ti_categorias_path, ti_perfis_abertura_path, ti_grupos_tecnicos_path, ti_solicitacoes_path, ti_solicitacao_campos_path(solicitacao), ti_permissoes_path ].each do |caminho|
        visit caminho
        expect(page).to have_css("table.collection-table")
        expect(sem_rolagem_horizontal?).to be(true), "rolagem horizontal em #{caminho}"
      end

      visit ti_grupos_tecnicos_path
      expect(tamanhos(novo: "main section a[title='Novo grupo']")).to eq(novo: [ 36, 36 ])
      print("ti-grupos-celular")
    end

    it "o painel ocupa a altura inteira, com os campos na largura do painel" do
      visit new_ti_grupo_tecnico_path

      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(tamanhos(nome: "#registro_nome", descricao: "#registro_descricao")).to eq(nome: [ 317.8, 44 ], descricao: [ 317.8, 112 ])
      expect(sem_rolagem_horizontal?).to be(true)
      print("ti-grupo-painel-celular")
    end
  end

  describe "chamados" do
    before do
      solicitante = create(:user, nome: "MARIA OLIVEIRA")
      create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }
      Ti::Chamado.create!(problema: solicitacao, solicitante: solicitante, solicitante_nome: solicitante.nome, solicitante_email: solicitante.email,
                          unidade_nome: "NÚCLEO DE INFORMÁTICA", aberto_em: Time.current)
      solicitacao.perfis_abertura << create(:ti_perfil_abertura, nome: "Geral", padrao: true)
      sign_in solicitante
    end

    def tecnico = User.find_by!(nome: "JOAO TECNICO")
    def chamado = Ti::Chamado.sole

    it "Meus chamados: código e solicitação levam ao chamado, selo azul de Aberto e \"Não atribuído\", como no seed" do
      visit ti_chamados_path
      usar_tema("light")

      linha = "##{ActionView::RecordIdentifier.dom_id(chamado)}"
      expect(page).to have_css("#{linha} td:nth-child(1) a", text: chamado.codigo).and have_css("#{linha} td:nth-child(2) a", text: "SEM INTERNET")
      expect([ estilo("#{linha} td:nth-child(2) p", "fontSize"), estilo("#{linha} td:nth-child(2) p + p", "fontSize") ]).to eq([ "15.2px", "14px" ])
      expect(page).to have_css("#{linha} td", text: "Não atribuído")
      selo = "#{linha} td:nth-child(4) span"
      expect([ find(selo).text, estilo(selo, "backgroundColor"), estilo(selo, "color") ]).to eq([ "Aberto", "rgb(238, 244, 255)", "rgb(49, 92, 207)" ])
      expect(tamanhos(selo: selo)[:selo].last).to eq(24)

      within(linha) { click_on chamado.codigo }
      expect(titulos_do_painel).to eq([ "solicitações de ti", "Chamado #{chamado.codigo}" ])
      expect(retangulo(painel)["largura"]).to eq(768)
      expect(page).to have_current_path(ti_chamados_path) # continua na lista
    end

    it "o painel Abrir chamado começa direto nos campos, com 44 px, e os painéis do chamado usam \"<ação> <código>\"" do
      visit new_ti_chamado_path
      usar_tema("light")
      expect(titulos_do_painel).to eq([ "novo chamado", "Abrir chamado" ])
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", solicitacao: "#chamado_problema")).to eq(cabecalho: [ 542, 81.5 ], solicitacao: [ 502, 44 ])
      # Sem texto de apoio antes do primeiro campo: 81,5 do cabeçalho + 20 de folga + rótulo.
      expect(retangulo("#chamado_problema")["y"] - retangulo(painel)["y"]).to be_within(0.5).of(125.3)

      visit edit_ti_chamado_path(chamado)
      expect(titulos_do_painel).to eq([ "editar chamado", "Atualizar #{chamado.codigo}" ])
      visit cancelamento_ti_chamado_path(chamado)
      expect(titulos_do_painel).to eq([ "cancelar chamado", "Cancelar #{chamado.codigo}" ])
      expect(tamanhos(motivo: "#motivo")).to eq(motivo: [ 502, 112 ])

      chamado.update_columns(status: "concluido", responsavel_id: tecnico.id)
      visit finalizacao_ti_chamado_path(chamado)
      expect(titulos_do_painel).to eq([ "finalizar chamado", "Finalizar #{chamado.codigo}" ])
      expect(tamanhos(resolveu: "#resolvido", avaliacao: "#avaliacao", comentario: "#comentario"))
        .to eq(resolveu: [ 502, 44 ], avaliacao: [ 502, 44 ], comentario: [ 502, 112 ])
      print("ti-finalizar-painel")
    end

    it "o painel de ação da operação usa o sobretítulo do seed e o código no título" do
      solicitacao.grupos_tecnicos << grupo
      grupo.vinculos_de_membro.create!(user: tecnico)
      chamado.update_columns(status: "em_atendimento", responsavel_id: tecnico.id)
      sign_in tecnico

      visit acao_ti_operacao_path(chamado, "concluir")
      expect(titulos_do_painel).to eq([ "conclusão", "Concluir atendimento #{chamado.codigo}" ])
      expect(tamanhos(nota: "#nota")).to eq(nota: [ 502, 112 ])
      visit acao_ti_operacao_path(chamado, "devolver")
      expect(titulos_do_painel).to eq([ "ajuste", "Pedir ajuste ao solicitante #{chamado.codigo}" ])

      visit ti_operacao_index_path(status: "em_atendimento")
      linha = "##{ActionView::RecordIdentifier.dom_id(chamado)}"
      expect(page).to have_css("#{linha} td:nth-child(1) a", text: chamado.codigo).and have_css("#{linha} td:nth-child(2) a", text: "SEM INTERNET")
      expect(estilo("#{linha} td:nth-child(2) p", "fontSize")).to eq("15.2px")
      print("ti-operacao")
    end

    it "no celular a lista, o painel do chamado e o painel de abertura não criam rolagem horizontal" do
      usar_tela_de_celular
      visit ti_chamados_path
      expect(tamanhos(abrir: "main section a[title='Abrir chamado']")).to eq(abrir: [ 36, 36 ])
      expect(sem_rolagem_horizontal?).to be(true)
      print("ti-chamados-celular")

      visit ti_chamado_path(chamado) # aberto direto pela URL: vai para a lista, que abre o painel
      expect(page).to have_css("#{painel} h2", text: "Chamado #{chamado.codigo}")
      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(retangulo("#resumo_do_chamado dl > div:nth-child(1)")).to include("largura" => 317.8)
      expect(sem_rolagem_horizontal?).to be(true)
      print("ti-chamado-celular")

      visit new_ti_chamado_path
      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(tamanhos(solicitacao: "#chamado_problema")).to eq(solicitacao: [ 317.8, 44 ])
      expect(sem_rolagem_horizontal?).to be(true)
    end
  end
end
