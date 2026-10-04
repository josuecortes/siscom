module Ti
  module Grupos
    module_function

    # Quem pode ser membro de grupo técnico: usuários ativos com alguma permissão concedida na TI.
    def elegiveis = ::User.ativos.where(id: Core::Api.ids_dos_usuarios_com_papel(modulo: :ti)).order(:nome, :id)
  end
end
