require "rails_helper"

RSpec.describe Legado::Registro do
  let(:user) { create(:user) }

  before { dar_papel_antigo(user, "master") }

  it "lê os papéis antigos" do
    expect(Legado::Papel.ids_dos_usuarios("master")).to eq([ user.id ])
    expect(Legado::Api.contagem_de_papeis).to eq("master" => 1)
  end

  it "nenhum model do Legado consegue gravar" do
    Rails.application.eager_load!
    modelos = described_class.descendants

    expect(modelos).to include(Legado::Papel)
    modelos.each do |modelo|
      registro = modelo.first || modelo.new
      expect { registro.save!(validate: false) }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { registro.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord) if registro.persisted?
      expect { modelo.delete_all }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { modelo.update_all(updated_at: Time.current) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
