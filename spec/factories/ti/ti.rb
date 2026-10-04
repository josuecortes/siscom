FactoryBot.define do
  factory :ti_categoria, class: "Ti::Categoria" do
    sequence(:nome) { |n| "CATEGORIA #{n}" }
  end

  factory :ti_perfil_abertura, class: "Ti::PerfilAbertura" do
    sequence(:nome) { |n| "PERFIL #{n}" }
  end

  factory :ti_grupo_tecnico, class: "Ti::GrupoTecnico" do
    sequence(:nome) { |n| "GRUPO #{n}" }
  end
end
