require "rails_helper"

RSpec.describe "Fuso horário" do # rubocop:disable RSpec/DescribeClass
  it "grava em UTC e mostra no horário do Amapá (UTC-3), em qualquer máquina" do
    expect(ActiveRecord.default_timezone).to eq(:utc)
    expect(Time.zone.tzinfo.name).to eq("America/Belem")
  end

  it "um registro feito às 16h locais fica 19h no banco e volta 16h na tela" do
    travel_to Time.zone.local(2026, 10, 3, 16, 0, 0) do
      registro = Core::Auditoria::Registrar.call(evento: "core.usuario.criado", ator: nil)
      no_banco = ActiveRecord::Base.connection.select_value("SELECT created_at::text FROM core_registros_auditoria WHERE id = #{registro.id}")

      expect(no_banco).to start_with("2026-10-03 19:00:00")
      expect(I18n.l(registro.reload.created_at, format: "%d/%m/%Y %H:%M")).to eq("03/10/2026 16:00")
    end
  end

  it "lê um horário antigo de produção (UTC) como horário local" do
    user = create(:user)
    ActiveRecord::Base.connection.execute("UPDATE users SET created_at = '2026-06-16 16:43:38' WHERE id = #{user.id}")

    expect(I18n.l(user.reload.created_at, format: "%d/%m/%Y %H:%M")).to eq("16/06/2026 13:43")
  end

  it "não sofre com horário de verão (o Amapá não adota)" do
    expect(Time.zone.local(2018, 12, 15, 12).utc_offset).to eq(-3.hours.to_i)
  end
end
