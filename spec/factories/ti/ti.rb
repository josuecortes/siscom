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

  factory :ti_problema, class: "Ti::Problema" do
    sequence(:nome) { |n| "SOLICITACAO #{n}" }
    descricao { "Resumo da solicitação" }
    categoria factory: :ti_categoria
  end

  factory :ti_campo_problema, class: "Ti::CampoProblema" do
    sequence(:rotulo) { |n| "Campo #{n}" }
    problema factory: :ti_problema
  end
end
