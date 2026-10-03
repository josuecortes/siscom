FactoryBot.define do
  factory :user do
    sequence(:nome) { |n| "USUARIO #{n}" }
    sequence(:email) { |n| "usuario#{n}@seed.ap.gov.br" }
    password { "Senha@Forte123" }
    password_confirmation { password }
  end
end
