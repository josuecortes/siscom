FactoryBot.define do
  factory :transporte_veiculo, class: "Transporte::Veiculo" do
    sequence(:placa) { |n| format("QLM%dA%02d", n % 10, n % 100) }
    marca { "TOYOTA" }
    modelo { "HILUX" }
    ano { 2022 }
    cor { "BRANCA" }
    capacidade { 4 }
    combustivel { "diesel" }
    consumo_km_por_litro { 9.5 }
    odometro_atual { 12_000 }
  end

  factory :transporte_motorista, class: "Transporte::Motorista" do
    user
    sequence(:nome) { |n| "MOTORISTA #{n}" }
    sequence(:cpf) { |n| %w[52998224725 11144477735 39053344705 86288366757 71460238001][n % 5] }
    data_nascimento { Date.new(1985, 1, 15) }
    sequence(:cnh_numero) { |n| "CNH#{n.to_s.rjust(8, '0')}" }
    cnh_categoria { "D" }
    cnh_validade { 2.years.from_now.to_date }
  end
end
