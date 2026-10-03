require "rails_helper"

RSpec.describe Core::Usuarios::Criar do
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }

  it "cadastra com senha temporária e troca obrigatória" do
    resultado = described_class.call(atributos: { nome: " ana  maria ", email: "ana@seed.ap.gov.br" }, criado_por: admin)
    user = resultado.objeto

    expect(resultado).to be_sucesso
    expect(user).to have_attributes(nome: "ANA MARIA", deve_trocar_senha: true, status: true)
    expect(user.senha_temporaria).to match(/\A\w{12}\z/)
    expect(user.valid_password?(user.senha_temporaria)).to be(true)
  end

  it "ignora atributos que não são de identificação" do
    resultado = described_class.call(atributos: { nome: "ANA", email: "ana@seed.ap.gov.br", status: false, versao_sessao: 9 },
                                     criado_por: admin)

    expect(resultado.objeto).to have_attributes(status: true, versao_sessao: 0)
  end

  it "devolve os erros de validação" do
    create(:user, nome: "ANA MARIA")

    resultado = described_class.call(atributos: { nome: "ana maria", email: "invalido" }, criado_por: admin)

    expect(resultado).to be_falha
    expect(resultado.objeto.errors.attribute_names).to contain_exactly(:nome, :email)
  end

  it "recusa quem não tem a permissão" do
    resultado = described_class.call(atributos: { nome: "ANA", email: "ana@seed.ap.gov.br" }, criado_por: create(:user))

    expect(resultado.erros).to eq([ "Você não pode cadastrar usuários." ])
    expect(User.where(email: "ana@seed.ap.gov.br")).to be_empty
  end
end
