module Legado
  # Papéis do Rolify do siscom antigo (tabelas `roles` e `users_roles`).
  class Papel < Registro
    self.table_name = "roles"

    # Ids dos usuários que tinham o papel global `nome` (sem recurso associado).
    def self.ids_dos_usuarios(nome)
      where(name: nome.to_s, resource_type: nil)
        .joins("INNER JOIN users_roles ON users_roles.role_id = roles.id")
        .distinct.pluck("users_roles.user_id")
    end
  end
end
