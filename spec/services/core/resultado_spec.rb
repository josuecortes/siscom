require "rails_helper"

RSpec.describe Core::Resultado do
  it "representa sucesso com objeto" do
    resultado = described_class.sucesso(:coisa)

    expect(resultado).to be_sucesso
    expect(resultado).not_to be_falha
    expect(resultado.objeto).to eq(:coisa)
    expect(resultado.erros).to be_empty
  end

  it "representa falha com uma ou várias mensagens" do
    expect(described_class.falha("Deu errado").erros).to eq([ "Deu errado" ])

    resultado = described_class.falha([ "Um", "Dois" ])
    expect(resultado).to be_falha
    expect(resultado.mensagem_de_erro).to eq("Um e Dois")
  end

  it "aceita um registro inválido e usa as mensagens dele" do
    user = User.new
    user.validate

    resultado = described_class.falha(user)

    expect(resultado.objeto).to be(user)
    expect(resultado.erros).to eq(user.errors.full_messages)
    expect(resultado.erros).not_to be_empty
  end

  it "aceita ActiveModel::Errors com objeto explícito" do
    user = User.new.tap(&:validate)

    resultado = described_class.falha(user.errors, objeto: :outro)

    expect(resultado.objeto).to eq(:outro)
    expect(resultado.erros).to eq(user.errors.full_messages)
  end

  it "é imutável" do
    resultado = described_class.falha("x")

    expect(resultado).to be_frozen
    expect(resultado.erros).to be_frozen
  end
end
