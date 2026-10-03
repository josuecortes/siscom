require "rails_helper"

RSpec.describe "compartilhado/_campo_data" do
  def renderizar(user)
    view.form_with(model: user, scope: :user, url: "/") do |f|
      return render(partial: "compartilhado/campo_data", locals: { f: f, campo: :data_nascimento, rotulo: "Data de nascimento" })
    end
  end

  it "mostra a data do banco em dd/mm/aaaa, com máscara" do
    html = renderizar(create(:user, data_nascimento: Date.new(1985, 1, 15)).reload)

    expect(html).to include('value="15/01/1985"', 'placeholder="dd/mm/aaaa"', 'data-mascara-tipo-value="data"', 'inputmode="numeric"')
    expect(html).not_to include("1985-01-15")
  end

  it "devolve o que foi digitado e o erro quando a data não existe" do
    user = build(:user, data_nascimento: "31/02/2020").tap(&:validate)

    html = renderizar(user)

    expect(html).to include('value="31/02/2020"', "Data de nascimento não é uma data válida (use dd/mm/aaaa)", 'aria-invalid="true"')
  end

  it "fica em branco sem data" do
    expect(renderizar(build(:user))).to include('value=""')
  end
end
