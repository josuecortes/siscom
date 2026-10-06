FactoryBot.define do
  factory :equipamentos_item, class: "Equipamentos::Item" do
    transient { unidade { association(:rh_unidade) } }

    tipo_equipamento { "Monitor" }
    marca { "DELL" }
    modelo { "P2419H" }
    sequence(:numero_patrimonio) { |n| "PAT#{n.to_s.rjust(5, '0')}" }
    rh_unidade_id { unidade.id }
    unidade_nome { [ unidade.sigla, unidade.nome ].compact.join(" - ") }
  end
end
