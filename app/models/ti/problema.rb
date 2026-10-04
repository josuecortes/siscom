module Ti
  # Solicitação do catálogo (na tela: "solicitação"; no seed: helpdesk_problem). É o que o usuário
  # escolhe ao abrir um chamado. Diz quem pode abrir (perfis de abertura), quem atende (grupos
  # técnicos) e, com os campos, qual formulário aparece.
  class Problema < ApplicationRecord
    self.table_name = "ti_problemas"

    STATUS = %w[ativo inativo].freeze
    PRIORIDADES = { "normal" => "Normal", "alta" => "Alta", "urgente" => "Urgente", "critica" => "Crítica" }.freeze

    belongs_to :categoria, class_name: "Ti::Categoria", inverse_of: :problemas
    has_many :vinculos_de_perfil, class_name: "Ti::ProblemaPerfil", foreign_key: :problema_id, inverse_of: :problema, dependent: :destroy
    has_many :perfis_abertura, through: :vinculos_de_perfil, source: :perfil_abertura
    has_many :vinculos_de_grupo, class_name: "Ti::ProblemaGrupo", foreign_key: :problema_id, inverse_of: :problema, dependent: :destroy
    has_many :grupos_tecnicos, through: :vinculos_de_grupo, source: :grupo_tecnico

    enum :status, STATUS.index_by(&:itself), validate: true
    enum :prioridade_padrao, PRIORIDADES.keys.index_by(&:itself), prefix: :prioridade, validate: true

    normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }
    normalizes :descricao, with: ->(descricao) { descricao.to_s.squish.presence }

    validates :nome, presence: true, length: { maximum: 120 }, uniqueness: { scope: :categoria_id, case_sensitive: false }
    validates :descricao, presence: true, length: { maximum: 500 }

    scope :ordenados, -> { order(:nome) }
    # Busca pelo nome da solicitação ou da categoria (use com joins(:categoria)).
    scope :buscar, ->(termo) {
      where("ti_problemas.nome LIKE :t OR ti_categorias.nome LIKE :t", t: "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%")
    }

    # Solicitações que o usuário pode abrir: as dos perfis padrão e as dos perfis que ele tem.
    scope :que_pode_abrir, ->(user) {
      perfis = Ti::PerfilAbertura.ativo.where(padrao: true)
                                 .or(Ti::PerfilAbertura.ativo.where(id: Ti::PerfilUsuario.where(user_id: user).select(:perfil_abertura_id)))
      ativo.where(id: Ti::ProblemaPerfil.where(perfil_abertura_id: perfis.select(:id)).select(:problema_id))
    }
  end
end
