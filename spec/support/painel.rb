# As telas de "ver" só existem dentro do painel (turbo-frame "painel"): abertas direto pela URL,
# redirecionam para a lista, que abre o painel sozinha.
module ApoioDePainel
  def ver_no_painel(caminho, **opcoes) = get(caminho, headers: { "Turbo-Frame" => "painel" }, **opcoes)
end

RSpec.configure { |config| config.include ApoioDePainel, type: :request }
