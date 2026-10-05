require "rails_helper"

RSpec.describe "TI: operação em tempo real", :js do
  let(:redes) { create(:ti_grupo_tecnico, nome: "Redes") }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tecnico) do
    create(:user, nome: "JOAO TECNICO").tap do |user|
      create(:core_concessao, user: user, modulo: "ti", papel: "tecnico")
      redes.vinculos_de_membro.create!(user: user)
    end
  end

  before do
    geral = create(:ti_perfil_abertura, nome: "Geral", padrao: true)
    create(:ti_problema, nome: "Sem internet", exige_triagem: false).tap do |solicitacao|
      solicitacao.perfis_abertura << geral
      solicitacao.grupos_tecnicos << redes
    end
  end

  # O aviso flutuante de uma ação recente pode estar por cima do botão; o clique vai direto nele.
  def fechar_conversa = find("button[aria-label='Fechar conversa']").execute_script("this.click()")

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "o chamado percorre o fluxo com dois usuários em navegadores diferentes, sem recarregar a página" do
    Capybara.using_session(:tecnico) do
      sign_in tecnico
      visit ti_operacao_index_path
      expect(page).to have_content("0 chamado(s) que ninguém assumiu ainda")
    end

    sign_in maria
    visit ti_chamados_path
    click_on "Abrir chamado"
    select "SEM INTERNET", from: "Solicitação *"
    within("[role='dialog']") { click_on "Abrir chamado" }
    expect(page).to have_css("#avisos", text: "aberto com sucesso")
    codigo = Ti::Chamado.sole.codigo
    within("tr", text: codigo) { click_on "Visualizar chamado" }
    within("[role='dialog']") do # "ver" abre no painel, só para leitura
      expect(page).to have_content("Ainda sem responsável")
      click_on "Fechar"
    end

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("1 chamado(s) que ninguém assumiu ainda") # apareceu sozinho
      print("ti-operacao-lista")
      within("tr", text: codigo) { click_on "Visualizar chamado" }
      within("[role='dialog']") do
        expect(page).to have_css("h2", text: "Chamado #{codigo}")
        print("ti-operacao-chamado")
        click_on "Fechar"
      end
      within("tr", text: codigo) { click_on "Assumir chamado" } # as ações ficam na linha da lista
      within("#confirmacao") { click_on "Assumir" }
      expect(page).to have_css("#avisos", text: "assumido por você")
      expect(page).to have_css("nav a", text: /Em atendimento\s*1/)
      click_on "Em atendimento" # as outras abas mostram só o que é dele
      expect(page).to have_css("tr", text: codigo)
    end

    expect(page).to have_css("nav a", text: /Em andamento\s*1/) # a lista da Maria mudou sozinha
    click_on "Em andamento"
    expect(page).to have_css("tr", text: "JOAO TECNICO")

    # A conversa começa quando o técnico assume. Ela abre pelo ícone flutuante; as mensagens chegam sem recarregar.
    within("tr", text: codigo) { click_on "Abrir conversa" }
    within("#lancador_conversas") do
      expect(page).to have_content("JOAO TECNICO assumiu o chamado. Use esta conversa para falar com Joao.")
      fill_in "Mensagem", with: "É na sala 12."
      click_on "Enviar mensagem"
      expect(page).to have_css("ol li[data-minha]", text: "É na sala 12.")
      expect(find_field("Mensagem").value).to eq("")
    end

    Capybara.using_session(:tecnico) do
      expect(page).to have_css("button[aria-label='Abrir conversas'] #contador_de_conversas", text: "1") # o indicativo aparece no ícone
      click_on "Abrir conversas"
      within("#lancador_conversas") do
        expect(page).to have_content("1 mensagem(ns) não lida(s)")
        click_on "#{codigo} · SEM INTERNET"
        expect(page).to have_css("ol li:not([data-minha])", text: "É na sala 12.")
        fill_in "Mensagem", with: "Estou a caminho."
        find_field("Mensagem").send_keys(:enter)
        expect(page).to have_css("ol li[data-minha]", text: "Estou a caminho.")
      end
      expect(page).to have_no_css("#contador_de_conversas span")
      print("ti-conversa")
      fechar_conversa
      expect(page).to have_no_css("#lancador_conversas ol")
    end
    within("#lancador_conversas") { expect(page).to have_css("ol li:not([data-minha])", text: "Estou a caminho.") }
    expect(page).to have_no_css("#contador_de_conversas span") # com a conversa aberta, a mensagem nova já conta como lida
    fechar_conversa

    Capybara.using_session(:tecnico) do
      within("tr", text: codigo) { click_on "Mudar etapa" }
      within("[role='dialog']") do
        expect(page).to have_css("h2", text: "Mudar etapa #{codigo}")
        print("ti-operacao-etapa")
        click_on "Pedir ajuste ao solicitante"
      end
      fill_in "Orientação para o solicitante *", with: "Qual é a sala?"
      within("[role='dialog']") { click_on "Pedir ajuste ao solicitante" }
      expect(page).to have_css("#avisos", text: "ajuste pedido ao solicitante")
    end

    expect(page).to have_css("nav a", text: /Ajustes\s*1/)
    click_on "Ajustes"
    within("tr", text: codigo) { click_on "Responder à TI" }
    fill_in "Sua resposta *", with: "Sala 12."
    click_on "Enviar resposta"
    expect(page).to have_css("#avisos", text: "Resposta enviada")

    Capybara.using_session(:tecnico) do
      expect(page).to have_css("tr", text: "Em trabalho") # voltou para ele sem recarregar
      within("tr", text: codigo) { click_on "Mudar etapa" }
      within("[role='dialog']") { click_on "Concluir atendimento" }
      fill_in "Resultado do atendimento *", with: "Cabo trocado."
      print("ti-operacao-concluir")
      within("[role='dialog']") { click_on "Concluir atendimento" }
      expect(page).to have_css("#avisos", text: "atendimento concluído")
    end

    expect(page).to have_css("nav a", text: /Concluídos\s*1/)
    click_on "Concluídos"
    within("tr", text: codigo) { click_on "Finalizar chamado" }
    within("[role='dialog']") do
      select "Sim, foi resolvido", from: "O atendimento resolveu o chamado? *"
      select "Muito bom", from: "Avaliação *"
      print("ti-finalizar")
      click_on "Finalizar chamado"
    end
    expect(page).to have_css("#avisos", text: "finalizado. Obrigado pela avaliação.")

    click_on "Finalizados"
    within("tr", text: codigo) { click_on "Visualizar chamado" }
    within("[role='dialog']") do
      expect(page).to have_content("Muito bom · resolveu o pedido").and have_content("Atendimento concluído: Cabo trocado.")
      click_on "Fechar"
    end
    within("tr", text: codigo) { click_on "Abrir conversa" }
    within("#lancador_conversas") do
      expect(page).to have_content("só leitura")
      expect(page).to have_no_field("Mensagem")
    end

    Capybara.using_session(:tecnico) do
      click_on "Finalizados"
      expect(page).to have_css("tr", text: "Finalizado") # o técnico vê o desfecho
    end
  end

  it "no celular a operação não cria rolagem horizontal" do
    Ti::Chamado.create!(problema: Ti::Problema.sole, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)
    sign_in tecnico
    usar_tela_de_celular
    visit ti_operacao_index_path
    expect(page).to have_content("1 chamado(s) que ninguém assumiu ainda")
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Visualizar chamado"
    expect(page).to have_css("[role='dialog'] h2", text: "Chamado")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
