require "rails_helper"

RSpec.describe Rh::Pessoa do
  it "normaliza nome, e-mail, CPF e celular" do
    pessoa = create(:rh_pessoa, nome: " maria  oliveira ", email: " Maria@SEED.ap.gov.br ", cpf: "529.982.247-25", celular: "(96) 99123-4567")

    expect(pessoa).to have_attributes(nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "52998224725", celular: "96991234567")
  end

  it "exige nome com sobrenome e e-mail único" do
    create(:rh_pessoa, email: "maria@seed.ap.gov.br")

    expect(build(:rh_pessoa, nome: "MARIA").tap(&:validate).errors[:nome]).to eq([ "deve ter nome e sobrenome" ])
    expect(build(:rh_pessoa, email: "MARIA@seed.ap.gov.br")).not_to be_valid
    expect(build(:rh_pessoa, email: "sem-arroba")).not_to be_valid
  end

  it "aceita CPF em branco, mas valida e não repete quando informado" do
    create(:rh_pessoa, cpf: "52998224725")

    expect(build(:rh_pessoa, cpf: "")).to be_valid
    expect(build(:rh_pessoa, cpf: "12345678901")).not_to be_valid
    expect(build(:rh_pessoa, cpf: "111.111.111-11")).not_to be_valid
    expect(build(:rh_pessoa, cpf: "529.982.247-25")).not_to be_valid
  end

  it "valida celular e data de nascimento em formato brasileiro" do
    pessoa = build(:rh_pessoa, celular: "9912", data_nascimento: "31/02/1990")

    expect(pessoa).not_to be_valid
    expect(pessoa.errors.attribute_names).to contain_exactly(:celular, :data_nascimento)
    expect(build(:rh_pessoa, data_nascimento: "15/01/1985").data_nascimento).to eq(Date.new(1985, 1, 15))
  end

  it "liga no máximo uma pessoa a cada conta" do
    user = create(:user)
    create(:rh_pessoa, user: user)

    expect(build(:rh_pessoa, user: user)).not_to be_valid
  end

  it "busca por nome, e-mail ou CPF" do
    create(:rh_pessoa, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "52998224725")
    create(:rh_pessoa, nome: "JOAO SANTOS")

    expect(described_class.buscar("oliv").count).to eq(1)
    expect(described_class.buscar("529.982").count).to eq(1)
    expect(described_class.buscar("joao").pluck(:nome)).to eq([ "JOAO SANTOS" ])
  end
end
