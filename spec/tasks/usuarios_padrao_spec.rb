require "rails_helper"
require "rake"

RSpec.describe "remaster:dev:usuarios_padrao" do # rubocop:disable RSpec/DescribeClass
  before do
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load Rails.root.join("lib/tasks/remaster/dev.rake")
    allow($stdout).to receive(:puts)
  end

  def rodar = Rake::Task["remaster:dev:usuarios_padrao"].tap(&:reenable).invoke

  it "cria um usuário por papel de cada módulo do catálogo, mais o usuário comum" do
    rodar

    cobertos = Core::Concessao.ativo.where(user: User.where("email LIKE '%@siscom.dev'")).pluck(:modulo, :papel)
    do_catalogo = Core::Catalogo.modulos.flat_map { |m| m.papeis.values.reject(&:automatico?).map { |papel| [ m.chave, papel.chave ] } }

    expect(cobertos).to match_array(do_catalogo)
    expect(Core::Autorizacao.new(User.find_by!(email: "usuario@siscom.dev")).papeis(:core)).to be_empty
  end

  it "é idempotente, repõe a senha e desbloqueia a conta" do
    rodar
    superadmin = User.find_by!(email: "superadmin@siscom.dev")
    superadmin.update!(password: "Outra@Senha123", deve_trocar_senha: true)
    superadmin.lock_access!

    expect { rodar }.not_to change(User, :count)

    expect(superadmin.reload).to have_attributes(deve_trocar_senha: false, locked_at: nil)
    expect(superadmin.valid_password?("Siscom@Dev2026")).to be(true)
    expect(Core::Concessao.ativo.where(user: superadmin).count).to eq(1)
  end

  it "não roda em produção" do
    allow(Rails.env).to receive(:production?).and_return(true)

    expect { rodar }.to raise_error(SystemExit)
    expect(User.where("email LIKE '%@siscom.dev'")).to be_empty
  end
end
