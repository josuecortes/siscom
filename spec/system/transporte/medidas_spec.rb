require "rails_helper"

# Textos e medidas do Transporte conferidos contra o código do seed (transport-requests-module.tsx,
# transport-drivers-module.tsx, transport-vehicles-module.tsx, transport-reports-module.tsx,
# transport-public-tracking-board.tsx e ui/responsive-form-panel.tsx), em 1400 px e 390 px.
# Com o seed rodando só foi medida a tela de senha do acompanhamento (a única sem login).
RSpec.describe "Transporte com as medidas do seed", :js do
  def com_papeis(nome, *papeis)
    create(:user, nome: nome).tap { |u| papeis.each { |papel| create(:core_concessao, user: u, modulo: "transporte", papel: papel) } }
  end

  let(:admin) { com_papeis("ADMIN DO TRANSPORTE", "admin", "motorista", "solicitante") }
  let(:maria) { com_papeis("MARIA OLIVEIRA", "solicitante") }
  let!(:veiculo) { create(:transporte_veiculo, placa: "QLM1A23") }

  before do
    Rh::Tabelas.garantir_padroes
    stub_request(:get, /openstreetmap\.org/).to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: "")
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

  def solicitacao(atributos = {})
    Transporte::Solicitacao.create!({ tipo: "normal", modo: "buscar_depois", busca_horas: 3, status: "aprovada", resumo: "Reunião na SEAD",
                                      saida_em: 2.hours.from_now, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email }.merge(atributos))
  end

  describe "painéis de formulário" do
    it "nova solicitação: sobretítulo, título e botão do seed, campos de 44 px e mapa de 280 px" do
      visit new_transporte_solicitacao_path

      expect(titulos_do_painel).to eq([ "transporte", "Nova solicitação de transporte" ])
      expect(page).to have_button("Abrir solicitação").and have_button("Adicionar passageiro").and have_button("Adicionar destino")
      expect(tamanhos(cabecalho: "#{painel} > div:first-child", saida: "#solicitacao_saida_em", motivo: "#solicitacao_resumo"))
        .to eq(cabecalho: [ 542, 81.5 ], saida: [ 502, 44 ], motivo: [ 502, 112 ])
      expect(tamanhos(mapa: ".leaflet-container")).to eq(mapa: [ 474, 280 ])
      expect(estilo("#{painel} fieldset > button", "borderRadius")).to eq("12px")
      print("transporte-medidas-nova-solicitacao")
    end

    it "reagendar, observação e cancelamento usam \"Transporte\" e o código no título" do
      pedido = solicitacao

      visit reagendamento_transporte_operacao_path(pedido)
      expect(titulos_do_painel).to eq([ "transporte", "Reagendar #{pedido.codigo}" ])
      expect(page).to have_button("Enviar reagendamento")

      visit new_transporte_solicitacao_observacao_path(pedido)
      expect(titulos_do_painel).to eq([ "transporte", "Observação · #{pedido.codigo}" ])
      expect(tamanhos(observacao: "#corpo")).to eq(observacao: [ 502, 112 ])

      visit cancelamento_transporte_operacao_path(pedido)
      expect(titulos_do_painel).to eq([ "transporte", "Cancelar #{pedido.codigo}" ])
    end

    it "o motorista inicia o serviço e finaliza o trecho com os títulos do seed" do
      pedido = solicitacao

      visit inicio_transporte_servico_path(pedido)
      expect(titulos_do_painel).to eq([ "transporte", "Iniciar serviço #{pedido.codigo}" ])
      expect(page).to have_button("Iniciar serviço")
      print("transporte-medidas-iniciar")

      Transporte::Servicos::Iniciar.call(solicitacao: pedido, ator: admin, veiculo_id: veiculo.id, odometro: 12_050)
      visit fim_transporte_servico_path(pedido)
      expect(titulos_do_painel).to eq([ "transporte", "Finalizar trecho #{pedido.codigo}" ])
      expect(page).to have_button("Finalizar trecho")
      expect(tamanhos(odometro: "#odometro")).to eq(odometro: [ 502, 44 ])
    end

    it "quando o trecho encerra a solicitação, o painel se chama Concluir serviço" do
      pedido = solicitacao(modo: "so_deixar", busca_horas: nil)
      Transporte::Servicos::Iniciar.call(solicitacao: pedido, ator: admin, veiculo_id: veiculo.id, odometro: 12_050)

      visit transporte_operacao_index_path(status: "em_servico")
      within("tr", text: pedido.codigo) { click_on "Concluir serviço" }
      expect(titulos_do_painel).to eq([ "transporte", "Concluir serviço #{pedido.codigo}" ])
    end
  end

  describe "listagens" do
    it "motoristas: colunas, resumo, larguras e texto de lista vazia do seed" do
      create(:transporte_motorista, nome: "JOAO DA SILVA")
      visit transporte_motoristas_path

      expect(all("#{cartao} thead th").map(&:text)).to eq([ "Nome", "CPF", "E-mail", "CNH", "Validade CNH", "Status", "Ações" ])
      expect(page).to have_content("1 motorista(s)").and have_no_content("registrado(s)")
      expect(estilo("#{cartao} table", "minWidth")).to eq("1080px")
      expect(tamanhos(status: "#{cartao} form select")).to eq(status: [ 220, 44 ])
      print("transporte-medidas-motoristas")

      visit transporte_motoristas_path(q: "ninguém")
      expect(page).to have_content("Nenhum motorista encontrado.")
    end

    it "veículos: resumo, larguras e texto de lista vazia do seed" do
      visit transporte_veiculos_path

      expect(page).to have_content("1 veículo(s)").and have_no_content("registrado(s)")
      expect(estilo("#{cartao} table", "minWidth")).to eq("1120px")
      expect(tamanhos(status: "#{cartao} form select")).to eq(status: [ 220, 44 ])

      visit transporte_veiculos_path(q: "nenhum")
      expect(page).to have_content("Nenhum veículo encontrado.")
    end

    it "operação: a aba de busca mostra \"Buscar até\" e o selo \"Atrasada\"" do
      atrasada = solicitacao(status: "busca", busca_prevista_em: 1.hour.ago)
      visit transporte_operacao_index_path(status: "busca")

      linha = "##{ActionView::RecordIdentifier.dom_id(atrasada)}"
      expect(page).to have_css("#operacao_lista thead th", text: "Buscar até")
      expect(page).to have_css("#{linha} td:nth-child(5) span", text: "Atrasada")
      expect([ estilo("#{linha} td:nth-child(5) span", "fontSize"), tamanhos(selo: "#{linha} td:nth-child(5) span")[:selo].last ]).to eq([ "11px", 22.5 ])
      # Tabela com o mínimo de 980 px do seed: em 1400 px cabe no cartão, sem esconder a coluna Ações.
      expect(retangulo("#operacao_lista table")["largura"]).to eq(retangulo("#operacao_lista")["largura"])
      print("transporte-medidas-operacao-busca")

      visit transporte_operacao_index_path(status: "cancelada")
      expect(page).to have_content("Nenhuma solicitação encontrada para os filtros atuais.")
    end

    it "relatórios: tipos em botões de 40 px, datas de 180 px e totais depois da tabela" do
      visit transporte_relatorios_path

      ativo = "#{cartao} nav a[aria-current='page']"
      expect(all("#{cartao} nav a").map(&:text)).to eq([ "Solicitações", "Veículos", "Motoristas" ])
      expect([ tamanhos(ativo: ativo)[:ativo].last, estilo(ativo, "borderRadius") ]).to eq([ 40, "12px" ])
      expect(tamanhos(inicio: "#inicio", fim: "#fim")).to eq(inicio: [ 180, 44 ], fim: [ 180, 44 ])
      expect(page).to have_content("0 registro(s) de").and have_content("Nenhum registro encontrado.")
      expect(retangulo("#{cartao} dl")["y"]).to be > retangulo("#{cartao} table")["y"]
      print("transporte-medidas-relatorios")
    end
  end

  describe "ver a solicitação" do
    it "abre num painel de 768 px por cima da lista, só para leitura, com o histórico" do
      pedido = Transporte::Solicitacoes::Abrir.call(user: maria, aberto_por: admin, fora_do_padrao: true,
                                                    atributos: { tipo: "normal", modo: "so_deixar", resumo: "Reunião na SEAD", saida_em: 2.hours.from_now,
                                                                 passageiros: [ { cpf: "529.982.247-25", nome: "Maria" } ],
                                                                 destinos: [ { nome: "SEAD", logradouro: "Avenida FAB", numero: "96", bairro: "Central", cidade: "Macapá", uf: "AP" } ] }).objeto
      visit transporte_operacao_index_path

      within("tr", text: pedido.codigo) { click_on "Visualizar solicitação" }
      expect(titulos_do_painel).to eq([ "operação", "Solicitação #{pedido.codigo}" ])
      expect(page).to have_current_path(transporte_operacao_index_path) # continua na lista
      expect(retangulo(painel)["largura"]).to eq(768)
      within(painel) do
        expect(page).to have_content("Histórico").and have_content("Solicitação aberta").and have_content("Observações (0)")
        expect(all("a, button").map { |item| item.text.presence || item[:"aria-label"] }).to eq([ "×", "Fechar" ]) # nenhuma ação dentro do painel
      end
      print("transporte-medidas-ver-solicitacao")
    end
  end

  describe "painel de acompanhamento" do
    before { Transporte::Configuracao.atual.update!(senha_do_painel: "painel123") }

    it "a tela de senha tem o cartão de 576 px, os textos e o botão do seed" do
      visit transporte_acompanhamento_path

      expect(page).to have_css("h1", text: "Acompanhamento em tempo real").and have_button("Entrar no acompanhamento")
      expect(tamanhos(cartao: "section", senha: "#senha", entrar: "button[type='submit']")).to eq(cartao: [ 576, 258 ], senha: [ 526, 44 ], entrar: [ 526, 44 ])
      expect([ estilo("h1", "fontSize"), estilo("section", "borderRadius") ]).to eq([ "24px", "16px" ])
      print("transporte-medidas-acompanhamento-senha")
    end

    it "com muitos cartões, a coluna rola sozinha até o fim e a atualização espera a rolagem" do
      25.times { |n| solicitacao(saida_em: (n + 1).hours.ago) }
      usar_tela(largura: 1600, altura: 900)
      visit transporte_acompanhamento_path
      fill_in "Senha de acesso", with: "painel123"
      click_on "Entrar no acompanhamento"

      lista = "#tv_saidas .tv-lista"
      expect(page).to have_css("#tv_saidas .tv-cartao", count: 25)
      sobra = page.evaluate_script("document.querySelector(#{lista.to_json}).scrollHeight - document.querySelector(#{lista.to_json}).clientHeight")
      expect(sobra).to be > 1000
      # O ciclo cresce: 5 s no topo + a sobra a 30 px/s + 4 s no fim (bem mais que os 30 s padrão).
      expect(find("[data-painel-tv-target='contagem']").text).to match(/\A[1-9] min \d+ s\z/)
      expect(page.evaluate_script("document.querySelector(#{lista.to_json}).scrollTop")).to eq(0) # parada no topo para leitura

      rolou = 20.times.any? { sleep 0.5; page.evaluate_script("document.querySelector(#{lista.to_json}).scrollTop") > 20 }
      expect(rolou).to be(true)
      expect(page.evaluate_script("document.querySelector('#tv_aprovacao .tv-lista').scrollTop")).to eq(0) # coluna que cabe na tela não rola
    end

    it "no celular o cartão fica a 16 px das bordas e a 40 px do topo" do
      usar_tela_de_celular
      visit transporte_acompanhamento_path

      expect(retangulo("section")).to include("x" => 16, "y" => 40, "largura" => 358)
      expect(sem_rolagem_horizontal?).to be(true)
      print("transporte-medidas-acompanhamento-senha-celular")
    end
  end

  describe "no celular (390 px)" do
    before { usar_tela_de_celular }

    it "as telas não criam rolagem horizontal e a ação do cabeçalho fica só com o ícone" do
      pedido = solicitacao
      [ transporte_solicitacoes_path, transporte_operacao_index_path, transporte_operacao_path(pedido),
        transporte_motoristas_path, transporte_veiculos_path, transporte_relatorios_path, transporte_permissoes_path, transporte_configuracoes_path ].each do |caminho|
        visit caminho
        expect(page).to have_css("main h1")
        expect(sem_rolagem_horizontal?).to be(true), "rolagem horizontal em #{caminho}"
      end

      visit transporte_solicitacoes_path
      expect(tamanhos(nova: "main section a[title='Nova solicitação']")).to eq(nova: [ 36, 36 ])
    end

    it "o painel de nova solicitação ocupa a altura inteira, com os campos e o mapa na largura do painel" do
      visit new_transporte_solicitacao_path

      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(tamanhos(saida: "#solicitacao_saida_em", mapa: ".leaflet-container")).to eq(saida: [ 317.8, 44 ], mapa: [ 289.8, 280 ])
      expect(sem_rolagem_horizontal?).to be(true)
      print("transporte-medidas-nova-solicitacao-celular")
    end

    it "ver a solicitação abre no painel de altura inteira (nunca numa página) e os relatórios cabem na tela" do
      pedido = solicitacao
      visit transporte_operacao_path(pedido) # aberto direto pela URL: vai para a lista, que abre o painel
      expect(page).to have_current_path(transporte_operacao_index_path(status: "aprovada"))
      expect(titulos_do_painel).to eq([ "operação", "Solicitação #{pedido.codigo}" ])
      expect(retangulo(painel)).to eq("x" => 31.2, "y" => 0, "largura" => 358.8, "altura" => 844)
      expect(retangulo("#resumo_da_solicitacao dl > div:nth-child(1)")).to include("largura" => 317.8)
      expect(sem_rolagem_horizontal?).to be(true)
      print("transporte-medidas-operacao-solicitacao-celular")
      within(painel) { click_on "Fechar" }
      expect(page).to have_no_css(painel)

      visit transporte_relatorios_path
      expect(tamanhos(exportar: "main section a[title='Exportar Excel']")).to eq(exportar: [ 36, 36 ])
      print("transporte-medidas-relatorios-celular")
    end
  end
end
