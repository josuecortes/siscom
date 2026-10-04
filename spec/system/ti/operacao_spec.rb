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

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "o chamado percorre o fluxo com dois usuários em navegadores diferentes, sem recarregar a página" do
    Capybara.using_session(:tecnico) do
      sign_in tecnico
      visit ti_operacao_index_path
      expect(page).to have_content("0 chamado(s) encontrado(s)")
    end

    sign_in maria
    visit ti_chamados_path
    click_on "Abrir chamado"
    select "SEM INTERNET", from: "Solicitação *"
    within("[role='dialog']") { click_on "Abrir chamado" }
    expect(page).to have_css("#avisos", text: "aberto com sucesso")
    codigo = Ti::Chamado.sole.codigo
    click_on "Visualizar chamado"
    expect(page).to have_content("Ainda sem responsável")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("1 chamado(s) encontrado(s)") # apareceu sozinho
      print("ti-operacao-lista")
      within("tr", text: codigo) { click_on "Visualizar chamado" }
      expect(page).to have_css("h1", text: "Chamado #{codigo}")
      click_on "Assumir chamado"
      expect(page).to have_content("Chamado assumido para atendimento por JOAO TECNICO.")
    end

    expect(page).to have_content("Em trabalho") # a página da Maria mudou sozinha
    expect(page).to have_content("JOAO TECNICO")

    Capybara.using_session(:tecnico) do
      click_on "Pedir ajuste ao solicitante"
      fill_in "Orientação para o solicitante *", with: "Qual é a sala?"
      click_on "Confirmar"
      expect(page).to have_css("#avisos", text: "ajuste pedido ao solicitante")
    end

    expect(page).to have_content("A TI precisa de uma resposta sua")
    click_on "Responder"
    fill_in "Sua resposta *", with: "Sala 12."
    click_on "Enviar resposta"
    expect(page).to have_css("#avisos", text: "Resposta enviada")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("Solicitante respondeu: Sala 12.")
      click_on "Concluir atendimento"
      fill_in "Resultado do atendimento *", with: "Cabo trocado."
      print("ti-operacao-concluir")
      click_on "Confirmar"
      expect(page).to have_css("#avisos", text: "atendimento concluído")
      print("ti-operacao-chamado")
    end

    expect(page).to have_content("Concluído")
    expect(page).to have_content("Atendimento concluído: Cabo trocado.")

    click_on "Finalizar chamado"
    within("[role='dialog']") do
      choose "Sim"
      choose "Muito bom"
      print("ti-finalizar")
      click_on "Finalizar chamado"
    end
    expect(page).to have_css("#avisos", text: "finalizado. Obrigado pela avaliação.")
    expect(page).to have_content("Muito bom · resolveu o pedido")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("Finalizado") # o técnico vê a avaliação sem recarregar
      expect(page).to have_content("Muito bom · resolveu o pedido")
    end
  end

  it "no celular a operação não cria rolagem horizontal" do
    Ti::Chamado.create!(problema: Ti::Problema.sole, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)
    sign_in tecnico
    usar_tela_de_celular
    visit ti_operacao_index_path
    expect(page).to have_content("1 chamado(s) encontrado(s)")
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Visualizar chamado"
    expect(page).to have_content("O que fazer")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
