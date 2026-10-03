module Legado
  # Porta de entrada do Legado para os outros módulos (somente leitura).
  module Api
    module_function

    # Ids dos usuários que tinham o papel antigo (Rolify), ex.: "master".
    def ids_dos_usuarios_com_papel(nome) = Papel.ids_dos_usuarios(nome)

    # { "master" => 1, "admin" => 19, ... }
    def contagem_de_papeis
      Papel.where(resource_type: nil)
           .joins("LEFT JOIN users_roles ON users_roles.role_id = roles.id")
           .group("roles.name").count("users_roles.user_id")
    end
  end
end
