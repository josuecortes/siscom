require "rails_helper"

# Botões do cabeçalho de página (porta de page-context-header.tsx): no celular
# só o ícone; a partir de sm, ícone + texto.
RSpec.describe "compartilhado/_acao_cabecalho" do
  def botao(**locais)
    render partial: "compartilhado/acao_cabecalho", locals: { rotulo: "Novo usuário", caminho: "/usuarios/novo" }.merge(locais)
    Capybara.string(rendered).find("a")
  end

  it "a ação principal é um link com ícone, nome acessível e texto escondido no celular" do
    link = botao(icone: :plus)

    expect(link[:href]).to eq("/usuarios/novo")
    expect(link[:title]).to eq("Novo usuário")
    expect(link["aria-label"]).to eq("Novo usuário")
    expect(link).to have_css("svg.h-4.w-4[aria-hidden='true']")
    expect(link).to have_css("span.sr-only.sm\\:not-sr-only", text: "Novo usuário")
  end

  it "a ação principal tem 36 px no celular e 40 px de altura a partir de sm, na cor de destaque" do
    expect(botao[:class].split).to include("h-9", "w-9", "sm:h-10", "sm:w-auto", "sm:px-4", "bg-[var(--accent-strong)]")
  end

  it "a ação secundária é um botão claro com seta para a esquerda" do
    link = botao(rotulo: "Voltar", secundaria: true)

    expect(link[:class].split).to include("h-9", "w-9", "border", "bg-[var(--surface-card)]")
    expect(link[:class].split).not_to include("bg-[var(--accent-strong)]")
    expect(link).to have_css("svg polygon[points^='497.333 239.999 80.092']") # cil-arrow-left
  end

  it "aceita atributos extras do link" do
    expect(botao(opcoes: { data: { turbo_frame: "painel" } })["data-turbo-frame"]).to eq("painel")
  end
end
