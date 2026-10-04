require "rails_helper"

RSpec.describe "compartilhado/_campo_escolha" do
  def renderizar(quantidade, **extras)
    opcoes = (1..quantidade).map { |n| [ "Opção #{n}", n ] }
    render partial: "compartilhado/campo_escolha",
           locals: { nome: "unidade[tipo_unidade_id]", id: "tipo", rotulo: "Tipo *", opcoes: opcoes, valor: 2, em_branco: "Selecione" }.merge(extras)
  end

  it "com até 8 opções é uma caixa de seleção, com o valor atual marcado" do
    html = renderizar(8)

    expect(html).to include('<select name="unidade[tipo_unidade_id]" id="tipo"', '<option selected="selected" value="2">Opção 2</option>',
                            '<option value="">Selecione</option>')
    expect(html).not_to include("data-controller=\"autocomplete\"")
  end

  it "com mais de 8 opções vira campo de busca, com as opções embutidas e o texto atual" do
    html = renderizar(9)

    expect(html).to include('data-controller="autocomplete"', 'name="unidade[tipo_unidade_id]"', 'value="Opção 2"', "Selecione · digite 3 letras")
    expect(html).to include("&quot;rotulo&quot;:&quot;Opção 9&quot;")
    expect(html).not_to include("<select")
  end

  it "mostra o erro do campo nos dois formatos" do
    expect(renderizar(3, erros: [ "não pode ficar em branco" ])).to include("Tipo não pode ficar em branco", 'aria-invalid="true"')
    expect(renderizar(12, erros: [ "não pode ficar em branco" ])).to include("Tipo não pode ficar em branco")
  end
end
