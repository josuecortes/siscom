require "rails_helper"

# Painel de TV em telas de vários tamanhos. Navegador de TV costuma se apresentar com largura pequena (ex.: 960 × 540
# ou menos para uma TV Full HD): deitada, a tela continua com as quatro colunas lado a lado, só reduzidas.
RSpec.describe "Painel de TV nos tamanhos de tela", :js do
  before do
    Ti::Configuracao.atual.update!(senha_do_painel: "painel123")
    visit ti_acompanhamento_path
    fill_in "Senha de acesso", with: "painel123"
    click_on "Entrar no acompanhamento"
    page.find_by_id("painel_tv")
  end

  def linhas_das_colunas = page.evaluate_script("Array.from(document.querySelectorAll('.tv-coluna')).map((c) => Math.round(c.getBoundingClientRect().top))").uniq.size
  def zoom = page.evaluate_script("getComputedStyle(document.getElementById('painel_tv')).zoom")
  def cabe_na_tela? = page.evaluate_script("document.getElementById('painel_tv').getBoundingClientRect().bottom <= window.innerHeight + 1")
  def ocupa_a_tela? = page.evaluate_script("(() => { const r = document.getElementById('painel_tv').getBoundingClientRect(); return Math.abs(r.width - innerWidth) <= 2 && Math.abs(r.height - innerHeight) <= 2 })()")

  it "TV que se apresenta com 960 × 540 ou 600 × 338: quatro colunas lado a lado, painel reduzido e inteiro na tela" do
    [ [ 960, 540, "0.75" ], [ 600, 338, "0.45" ] ].each do |largura, altura, reducao|
      usar_tela(largura: largura, altura: altura)
      visit ti_acompanhamento_path

      expect([ linhas_das_colunas, zoom, cabe_na_tela? ]).to eq([ 1, reducao, true ])
    end
  end

  it "computador: quatro colunas, sem redução; celular em pé: uma embaixo da outra" do
    usar_tela(largura: 1600, altura: 900)
    visit ti_acompanhamento_path
    expect([ linhas_das_colunas, zoom ]).to eq([ 1, "1" ])

    usar_tela_de_celular
    visit ti_acompanhamento_path
    expect(linhas_das_colunas).to eq(4)
  end

  it "modo compatível: colunas sempre lado a lado (flexbox), na tela toda e reduzidas ou ampliadas pela largura (a TV Philips informa 1920 × 1080)" do
    [ [ 600, 338 ], [ 600, 900 ], [ 1920, 1080 ] ].each do |largura, altura|
      usar_tela(largura: largura, altura: altura)
      visit ti_acompanhamento_path(modo: "compativel")
      page.find("#painel_tv[data-compativel='1']")

      expect([ linhas_das_colunas, page.evaluate_script("getComputedStyle(document.querySelector('.tv-colunas')).display"), zoom.to_f, ocupa_a_tela? ])
        .to eq([ 1, "flex", (largura / 1280.0).round(6), true ])
    end
  end
end
