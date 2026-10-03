require "rails_helper"

RSpec.describe Core::Concessao do
  let(:user) { create(:user) }

  it "é válida com papel do catálogo" do
    expect(build(:core_concessao, user: user, papel: "auditor")).to be_valid
  end

  it "recusa papel ou módulo fora do catálogo" do
    expect(build(:core_concessao, user: user, papel: "fantasma")).not_to be_valid
    expect(build(:core_acesso, user: user, modulo: "fantasma")).not_to be_valid
  end

  it "exige tipo e id de escopo juntos" do
    expect(build(:core_concessao, user: user, escopo_tipo: "rh_unidade")).not_to be_valid
    expect(build(:core_concessao, user: user, escopo_id: 1)).not_to be_valid
    expect(build(:core_concessao, user: user, escopo_tipo: "rh_unidade", escopo_id: 1)).to be_valid
  end

  it "recusa acesso de outro usuário ou módulo" do
    acesso_alheio = create(:core_acesso, user: create(:user), modulo: "core")

    expect(build(:core_concessao, user: user, acesso: acesso_alheio)).not_to be_valid
  end

  it "não repete concessão ativa do mesmo papel e escopo" do
    create(:core_concessao, user: user, papel: "auditor")

    expect(build(:core_concessao, user: user, papel: "auditor")).not_to be_valid
    expect(build(:core_concessao, user: user, papel: "auditor", escopo_tipo: "rh_unidade", escopo_id: 1)).to be_valid
  end

  it "permite conceder de novo depois de revogar" do
    create(:core_concessao, user: user, papel: "auditor", status: "inativo")

    expect(build(:core_concessao, user: user, papel: "auditor")).to be_valid
  end

  it "o banco também barra a duplicidade ativa" do
    primeira = create(:core_concessao, user: user, papel: "auditor")
    repetida = primeira.dup

    expect { repetida.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "um acesso por usuário e módulo" do
    create(:core_acesso, user: user, modulo: "core")

    expect(build(:core_acesso, user: user, modulo: "core")).not_to be_valid
  end
end
