module Ti
  module Grupos
    # Deixa o grupo técnico exatamente com os membros informados. Só entra quem já tem
    # alguma permissão operacional na TI (administrador, supervisor, triador ou técnico).
    class DefinirMembros
      def self.call(...) = new(...).call

      def initialize(grupo:, user_ids:, definido_por:)
        @grupo = grupo
        @user_ids = Array(user_ids).map(&:to_i).select(&:positive?).uniq
        @definido_por = definido_por
      end

      def call
        unless Core::Autorizacao.new(@definido_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @grupo)
        end

        elegiveis = Ti::Grupos.elegiveis.where(id: @user_ids).pluck(:id)
        atuais = @grupo.vinculos_de_membro.pluck(:user_id)
        entram = elegiveis - atuais
        saem = atuais - elegiveis

        Ti::MembroGrupo.transaction do
          @grupo.vinculos_de_membro.where(user_id: saem).destroy_all
          entram.each { |user_id| @grupo.vinculos_de_membro.create!(user_id: user_id, concedido_por: @definido_por) }
        end

        if entram.any? || saem.any?
          Core::Api.auditar(evento: "ti.grupo_tecnico.membros_alterados", alvo: @grupo, ator: @definido_por, dados: { entraram: entram, sairam: saem })
          Core::Api.notificar(destinatarios: ::User.where(id: entram), evento: "ti.grupo_tecnico.entrou", titulo: "Você entrou em um grupo técnico",
                              mensagem: "Você agora faz parte do grupo técnico #{@grupo.nome} da TI.")
        end
        Core::Resultado.sucesso(@grupo)
      end
    end
  end
end
