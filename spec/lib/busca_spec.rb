require "rails_helper"

RSpec.describe Busca do
  it "normaliza o termo: maiúsculas, sem acento, sem espaços sobrando e com os curingas neutralizados" do
    expect(described_class.normalizar("  reunião   de  Março ")).to eq("REUNIAO DE MARCO")
    expect(described_class.padrao("100%_ok")).to eq("%100\\%\\_OK%")
    expect(described_class.normalizar("reuni\xC3\xA3o \xFF".b)).to eq("REUNIAO") # bytes sem codificação declarada, com lixo
  end

  it "acha com ou sem acento, em maiúsculas ou minúsculas, dos dois lados" do
    create(:user, nome: "JOÃO CONCEIÇÃO")
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")

    achados = [ "joao", "JOÃO", "conceicao", "Conceição", "MARIA@seed", "ninguém" ].map { |termo| User.buscar(termo).pluck(:nome) }

    expect(achados).to eq([ [ "JOÃO CONCEIÇÃO" ] ] * 4 + [ [ "MARIA OLIVEIRA" ], [] ])
  end

  it "vale para texto gravado com minúsculas (resumo do transporte, nota do histórico de equipamentos)" do
    item = create(:equipamentos_item)
    item.registrar_evento("editado", nil, "Descrição: vazio → Situação de manutenção")

    expect(Equipamentos::Evento.where(described_class.em("equipamentos_eventos.nota"), t: described_class.padrao("situacao de MANUTENÇÃO"))).to exist
  end
end
