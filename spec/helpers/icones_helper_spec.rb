require "rails_helper"

RSpec.describe IconesHelper do
  it "gera SVG inline decorativo com a classe informada" do
    svg = helper.icone(:moon, classe: "h-5 w-5")

    expect(svg).to start_with('<svg class="h-5 w-5" aria-hidden="true" ')
    expect(svg).to be_html_safe
  end

  it "aceita nome com underscore e título acessível" do
    svg = helper.icone(:hamburger_menu, titulo: "Menu")

    expect(svg).to include('role="img"', 'aria-label="Menu"')
  end

  it "falha para ícone inexistente" do
    expect { helper.icone(:nao_existe) }.to raise_error(ArgumentError, /ícone desconhecido/)
  end
end
