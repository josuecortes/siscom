require "rails_helper"

# Tela Início: saudação, o que precisa de atenção, atalhos, em andamento, operação e links úteis.
RSpec.describe "Início" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:internet) { create(:ti_problema, nome: "SEM INTERNET") }

  def pagina = Nokogiri::HTML(response.body)
  def cartoes = pagina.css("#atencao li a").map { |cartao| [ cartao.css("span").first.text.strip, cartao.css("span span").first.text.strip, cartao["href"] ] }
  def atalhos = pagina.css("#atalhos a").map { |link| link.text.squish }
  def chamado(status) = Ti::Chamado.create!(problema: internet, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current, status: status)

  it "sem nada pendente: tudo em dia, os atalhos de quem só pede e os links úteis em nova aba" do
    sign_in maria

    get root_path

    expect(response.body).to include("Tudo em dia: nada esperando por você.")
    expect(atalhos).to eq([ "Abrir chamado de TI", "Meus equipamentos", "Minha ficha" ])
    expect(pagina.at_css("#atalhos a[href='/ti/chamados/novo']")["data-turbo-frame"]).to eq("painel")
    expect(pagina.css("#links_uteis a").map { |link| [ link.css("span span").first.text.strip, link["target"] ] })
      .to eq([ [ "Manual do PRODOC", "_blank" ], [ "Como fazer upload e assinatura no SIGDOC", "_blank" ], [ "Como acessar o webmail institucional", "_blank" ],
               [ "Como acessar o servidor de arquivos", "_blank" ] ])
    expect(pagina.css("[id^='operacao_']")).to be_empty
  end

  it "mostra só o que precisa de atenção, com a quantidade e o caminho certo" do
    2.times { chamado("concluido") }
    chamado("em_atendimento")
    Core::Api.notificar(destinatarios: maria, evento: "core.teste.aviso", titulo: "Aviso", ator: nil)
    sign_in maria

    get root_path

    expect(cartoes).to eq([ [ "1", "Notificações não lidas", "/minha-area/notificacoes" ], [ "2", "Chamados de TI para finalizar", "/ti/chamados?status=concluido" ] ])
    expect(pagina.css("#andamento_meus-chamados-de-ti li a").map { |item| item.text.squish }).to eq([ "#{Ti::Chamado.last.codigo} · SEM INTERNET Aguardando técnico Em trabalho" ])
  end

  it "quem pede transporte vê o atalho, as solicitações em andamento e o reagendamento para responder" do
    create(:core_concessao, user: maria, modulo: "transporte", papel: "solicitante")
    Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: "reagendada", resumo: "Reunião na SEAD", saida_em: 2.days.from_now, solicitante: maria,
                                    solicitante_nome: maria.nome, solicitante_email: maria.email)
    sign_in maria

    get root_path

    expect(atalhos).to include("Nova solicitação de transporte")
    expect(cartoes).to eq([ [ "1", "Reagendamento de transporte para responder", "/transporte/solicitacoes?status=reagendada" ] ])
    expect(pagina.css("#andamento_minhas-solicitacoes-de-transporte li").text).to include("Reunião na SEAD", "Reagendada")
  end

  it "quem trabalha na Operação vê os números e os botões da Operação e do Acompanhamento" do
    create(:core_concessao, user: maria, modulo: "ti", papel: "supervisor")
    chamado("aberto")
    sign_in maria

    get root_path

    operacao = pagina.at_css("#operacao_operacao-da-ti")
    expect(operacao.css("dd").map(&:text)).to eq(%w[1 0])
    expect(operacao.css("a").map { |link| [ link.text, link["href"] ] }).to eq([ [ "Abrir a Operação", "/ti/operacao" ], [ "Acompanhamento", "/ti/acompanhamento/sobre" ] ])
  end
end
