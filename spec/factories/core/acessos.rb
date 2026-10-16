FactoryBot.define do
  factory :core_acesso, class: "Core::Acesso" do
    user
    modulo { "core" }
    status { "ativo" }
  end

  factory :core_concessao, class: "Core::Concessao" do
    user
    modulo { "core" }
    papel { "auditor" }
    status { "ativo" }
    acesso { Core::Acesso.find_or_create_by!(user: user, modulo: modulo) }
  end
end
