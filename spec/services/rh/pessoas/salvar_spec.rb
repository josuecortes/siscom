require "rails_helper"

RSpec.describe Rh::Pessoas::Salvar do
  let(:operador) { create(:user, nome: "OPERADOR DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }
  let(:atributos) { { nome: "Maria Oliveira", email: "maria@seed.ap.gov.br", celular: "(96) 99123-4567", cpf: "529.982.247-25" } }

  def salvar(pessoa: Rh::Pessoa.new, **extras)
    described_class.call(pessoa: pessoa, atributos: atributos.merge(extras), salvo_por: operador)
  end

  it "cadastra a pessoa e cria a conta com senha temporária" do
    resultado = salvar(data_nascimento: "15/01/1985", sexo: "feminino")
    pessoa = resultado.objeto

    expect(resultado).to be_sucesso
    expect(pessoa).to have_attributes(nome: "MARIA OLIVEIRA", cpf: "52998224725", celular: "96991234567", data_nascimento: Date.new(1985, 1, 15))
    expect(pessoa.user).to have_attributes(nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", deve_trocar_senha: true)
    expect(pessoa.user.valid_password?(pessoa.senha_temporaria)).to be(true)
    expect(Core::RegistroAuditoria.where(modulo: "rh").sole).to have_attributes(evento: "pessoa.criada", ator: operador)
  end

  it "aproveita a conta que já existe com o mesmo e-mail, sem trocar a senha" do
    conta = create(:user, nome: "MARIA O.", email: "maria@seed.ap.gov.br", password: "Senha@Forte123")

    pessoa = salvar.objeto

    expect(pessoa.user).to eq(conta)
    expect(pessoa.senha_temporaria).to be_nil
    expect(conta.reload).to have_attributes(nome: "MARIA OLIVEIRA")
    expect(conta.valid_password?("Senha@Forte123")).to be(true)
  end

  it "recusa e-mail de conta que já pertence a outra pessoa" do
    create(:rh_pessoa, user: create(:user, email: "maria@seed.ap.gov.br"), email: "outra@seed.ap.gov.br")

    resultado = salvar

    expect(resultado.objeto.errors[:email]).to eq([ "já pertence à conta de outra pessoa" ])
    expect(Rh::Pessoa.count).to eq(1)
  end

  it "exige celular e CPF no cadastro e não cria a conta se a pessoa é inválida" do
    resultado = salvar(celular: "", cpf: "", nome: "Maria")

    expect(resultado.objeto.errors.attribute_names).to contain_exactly(:celular, :cpf, :nome)
    expect(User.where(email: "maria@seed.ap.gov.br")).to be_empty
  end

  it "o vínculo é opcional, mas completo quando informado" do
    tipo = create(:rh_tipo_vinculo)
    cargo = create(:rh_cargo)

    incompleto = salvar(vinculo: { tipo_vinculo_id: tipo.id, cargo_id: "", data_inicio: "" })
    expect(incompleto).to be_falha

    completo = salvar(vinculo: { tipo_vinculo_id: tipo.id, cargo_id: cargo.id, data_inicio: "01/02/2020" })
    expect(completo.objeto.vinculo).to have_attributes(tipo_vinculo: tipo, cargo: cargo, data_inicio: Date.new(2020, 2, 1))
  end

  it "ao editar, sincroniza nome e e-mail com a conta e registra as mudanças" do
    pessoa = salvar.objeto

    resultado = described_class.call(pessoa: pessoa, atributos: { nome: "Maria O. Souza", email: "maria.souza@seed.ap.gov.br" }, salvo_por: operador)

    expect(resultado).to be_sucesso
    expect(pessoa.user.reload).to have_attributes(nome: "MARIA O. SOUZA", email: "maria.souza@seed.ap.gov.br")
    expect(Core::RegistroAuditoria.where(evento: "pessoa.atualizada").sole.dados["mudancas"].keys).to contain_exactly("nome", "email")
  end

  it "pessoa importada sem CPF pode ser editada sem informar o CPF" do
    pessoa = create(:rh_pessoa, user: create(:user), cpf: nil, celular: nil)

    resultado = described_class.call(pessoa: pessoa, atributos: { celular: "96991234567" }, salvo_por: operador)

    expect(resultado).to be_sucesso
  end

  it "recusa quem não tem a permissão" do
    resultado = described_class.call(pessoa: Rh::Pessoa.new, atributos: atributos, salvo_por: create(:user))

    expect(resultado.erros).to eq([ "Você não pode cadastrar ou editar pessoas." ])
  end
end
