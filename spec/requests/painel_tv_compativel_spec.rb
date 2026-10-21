require "rails_helper"

# O script do modo compatível roda em navegadores de TV antigos: só JavaScript antigo (ES5), senão ele mesmo quebra.
RSpec.describe "Painel de TV: script do modo compatível" do
  it "não usa recursos de JavaScript novo (let/const, =>, crases, classes, ?., ??, ...)" do
    script = Rails.root.join("app/views/compartilhado/painel_tv/_modo_compativel.html.erb").read[/<%= javascript_tag.*?%>(.*)<% end %>/m, 1]

    proibidos = { "let" => /\blet\s/, "const" => /\bconst\s/, "=>" => /=>/, "crase" => /`/, "class" => /\bclass\s/, "?." => /\?\./, "??" => /\?\?/, "..." => /\.\.\./ }
    expect(proibidos.select { |_, padrao| script.match?(padrao) }.keys).to eq([])
  end

  it "o painel leva a hora do servidor e o modo forçado para o script" do
    Ti::Configuracao.atual.update!(senha_do_painel: "painel123")
    post ti_acompanhamento_path, params: { senha: "painel123" }

    get ti_acompanhamento_path(modo: "compativel")

    raiz = Nokogiri::HTML(response.body).at_css("#painel_tv")
    expect([ raiz["data-modo"], (raiz["data-agora-servidor"].to_i / 1000 - Time.current.to_i).abs < 5 ]).to eq([ "compativel", true ])
  end
end
