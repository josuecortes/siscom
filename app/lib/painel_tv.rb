# Peças comuns dos painéis de acompanhamento para TV (Transporte e TI): cada módulo monta o seu quadro
# (colunas de itens, cada item com o nível de urgência e o aviso que explica por quê) e a tela é a mesma
# (compartilhado/painel_tv/quadro).
#
# Níveis, do mais grave para o mais calmo: critico (vermelho: passou da hora), urgente (laranja: falta
# pouco), atencao (amarelo: convém olhar), normal (cinza).
module PainelTv
  NIVEIS = %w[critico urgente atencao normal].freeze
  Item = Data.define(:codigo, :nome, :detalhe, :horario, :nivel, :aviso)
  Coluna = Data.define(:chave, :titulo, :vazio, :itens)

  module_function

  # Em cada coluna, o mais urgente vem primeiro (e, no mesmo nível, a ordem em que vieram).
  def ordenar(itens) = itens.sort_by.with_index { |item, indice| [ NIVEIS.index(item.nivel), indice ] }

  # Quantos itens em cada nível, no quadro todo (para o resumo do cabeçalho).
  def contagem(colunas) = colunas.flat_map(&:itens).map(&:nivel).tally

  # Minutos de `agora` até `momento` (negativo: já passou).
  def minutos_ate(momento, agora) = ((momento - agora) / 60).round

  # "em 45 min", "há 2 h 10 min", "há 2 dias".
  def quando(minutos) = minutos.negative? ? "há #{duracao(-minutos)}" : "em #{duracao(minutos)}"

  def duracao(minutos)
    return "menos de 1 min" if minutos < 1
    return "#{minutos} min" if minutos < 60
    return "#{minutos / 1440} dia#{'s' if minutos >= 2880}" if minutos >= 1440

    resto = minutos % 60
    resto.zero? ? "#{minutos / 60} h" : "#{minutos / 60} h #{resto} min"
  end
end
