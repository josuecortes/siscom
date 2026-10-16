FactoryBot.define do
  factory :rh_tipo_unidade, class: "Rh::TipoUnidade" do
    sequence(:nome) { |n| "TIPO #{n}" }
  end

  factory :rh_tipo_local, class: "Rh::TipoLocal" do
    sequence(:nome) { |n| "LOCAL #{n}" }
  end

  factory :rh_cargo, class: "Rh::Cargo" do
    sequence(:nome) { |n| "CARGO #{n}" }
  end

  factory :rh_funcao, class: "Rh::Funcao" do
    sequence(:nome) { |n| "FUNCAO #{n}" }
  end

  factory :rh_tipo_vinculo, class: "Rh::TipoVinculo" do
    sequence(:nome) { |n| "VINCULO #{n}" }
  end

  factory :rh_unidade, class: "Rh::Unidade" do
    sequence(:nome) { |n| "UNIDADE #{n}" }
    sequence(:sigla) { |n| "UN#{n}" }
    tipo_unidade factory: :rh_tipo_unidade
  end

  factory :rh_pessoa, class: "Rh::Pessoa" do
    sequence(:nome) { |n| "PESSOA NUMERO #{n}" }
    sequence(:email) { |n| "pessoa#{n}@seed.ap.gov.br" }
  end

  factory :rh_lotacao, class: "Rh::Lotacao" do
    pessoa factory: :rh_pessoa
    unidade factory: :rh_unidade
    funcao factory: :rh_funcao
    data_inicio { Date.current }
    lotado_em { Time.current }
  end
end
