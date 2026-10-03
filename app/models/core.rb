# Módulo Core: usuários, login, acessos e permissões, auditoria, notificações,
# chat, configurações e fontes de referência. Tabelas com prefixo `core_`
# (exceto `users`, herdada do siscom antigo).
module Core
  def self.table_name_prefix = "core_"
end
