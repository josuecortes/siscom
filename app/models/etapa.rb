class Etapa < ApplicationRecord
  belongs_to :acao

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Finalizada": 3, "Paralizada": 4, "Cancelada": 5 }

  def nome_etapa_nome_acao
    acao = self.acao
    if acao
      "#{self.nome} | #{acao.nome}"
    else 
      self.nome
    end
  end
end
