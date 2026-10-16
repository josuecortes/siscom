module Ti
  module Chamados
    # Quem vê e opera quais chamados. Quem supervisiona (supervisor e administrador) vê todos;
    # triador e técnico veem os chamados das solicitações dos grupos técnicos de que são membros.
    module Acesso
      OPERAR = %w[ti.chamados.triar ti.chamados.atender ti.chamados.supervisionar].freeze
      SUPERVISIONAR = "ti.chamados.supervisionar".freeze

      module_function

      def opera?(user) = OPERAR.any? { |permissao| Core::Autorizacao.new(user).pode?(permissao) }
      def supervisiona?(user) = Core::Autorizacao.new(user).pode?(SUPERVISIONAR)
      def triador?(user) = Core::Autorizacao.new(user).papeis(:ti).include?("triagem")
      def atende?(user) = Core::Autorizacao.new(user).pode?("ti.chamados.atender")

      def ids_dos_grupos(user) = Ti::MembroGrupo.where(user: user).joins(:grupo_tecnico).merge(Ti::GrupoTecnico.ativo).pluck(:grupo_tecnico_id)

      def visiveis(user)
        return Ti::Chamado.none unless opera?(user)
        return Ti::Chamado.all if supervisiona?(user)

        Ti::Chamado.where(problema_id: Ti::ProblemaGrupo.where(grupo_tecnico_id: ids_dos_grupos(user)).select(:problema_id))
      end

      def pode_operar?(user, chamado) = visiveis(user).exists?(id: chamado.id)

      # Pode pegar o chamado por conta própria: supervisão sempre; os demais, só se algum grupo
      # em comum com a solicitação permite ("os membros podem pegar chamados").
      def pode_assumir_sozinho?(user, chamado)
        return true if supervisiona?(user)

        chamado.problema.grupos_tecnicos.ativo.where(id: ids_dos_grupos(user), permite_autoatribuicao: true).exists?
      end

      # Usuários que podem receber o chamado (membros ativos dos grupos da solicitação, com permissão na TI).
      def operadores_do(chamado)
        grupos = chamado.problema.grupos_tecnicos.ativo.select(:id)
        ::User.ativos.where(id: Ti::MembroGrupo.where(grupo_tecnico_id: grupos).select(:user_id))
              .where(id: Core::Api.ids_dos_usuarios_com_papel(modulo: :ti)).order(:nome, :id)
      end
    end
  end
end
