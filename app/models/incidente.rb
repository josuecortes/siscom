class Incidente < ApplicationRecord
  validates_presence_of :descricao, :texto_explicativo, :previsao_de_retorno, :data_hora_inicio
  validates_presence_of :data_hora_fim, if: Proc.new{ |i| i.ativo == false }
end
