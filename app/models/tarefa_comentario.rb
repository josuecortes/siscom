class TarefaComentario < ApplicationRecord
  belongs_to :tarefa
  belongs_to :user

  validates :texto, presence: true
end
