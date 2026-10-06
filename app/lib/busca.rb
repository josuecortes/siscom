# Busca por texto sem diferenciar maiúsculas, minúsculas nem acentos ("reuniao" acha "Reunião").
# O banco usa collation C (produção também): nela UPPER e ILIKE não mexem em letra acentuada, então a comparação
# é feita com os dois lados em maiúsculas e sem acento: a coluna pelo SQL daqui, o termo pelo Ruby.
#
#   scope :buscar, ->(termo) { where(Busca.em("users.nome", "users.email"), t: Busca.padrao(termo)) }
#
# Os nomes de coluna vêm sempre do código, nunca do que o usuário digitou.
module Busca
  COM_ACENTO = "ÁÀÂÃÄÅáàâãäåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÕÖóòôõöÚÙÛÜúùûüÇçÑñ".freeze
  SEM_ACENTO = "AAAAAAAAAAAAEEEEEEEEIIIIIIIIOOOOOOOOOOUUUUUUUUCCNN".freeze

  module_function

  # O termo digitado, em maiúsculas e sem acento.
  def normalizar(termo) = termo.to_s.squish.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").upcase

  # Padrão para o LIKE: "%TERMO%", com os curingas do que foi digitado neutralizados.
  def padrao(termo) = "%#{ActiveRecord::Base.sanitize_sql_like(normalizar(termo))}%"

  # Expressão SQL da coluna em maiúsculas e sem acento.
  def coluna(nome) = "translate(upper(#{nome}::text), '#{COM_ACENTO}', '#{SEM_ACENTO}')"

  # Condição "uma das colunas contém o termo", para usar com `t: Busca.padrao(termo)`.
  def em(*colunas) = colunas.flatten.map { |nome| "#{coluna(nome)} LIKE :t" }.join(" OR ")

  # O mesmo para consultas montadas com Arel (nome de coluna vindo de configuração).
  def arel(atributo)
    texto = Arel::Nodes::NamedFunction.new("CAST", [ atributo.as(Arel.sql("text")) ])
    Arel::Nodes::NamedFunction.new("translate", [ Arel::Nodes::NamedFunction.new("upper", [ texto ]), Arel::Nodes.build_quoted(COM_ACENTO), Arel::Nodes.build_quoted(SEM_ACENTO) ])
  end
end
