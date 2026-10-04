module Ti
  module Perfis
    # Deixa o usuário exatamente com os perfis de abertura (ativos) informados.
    # Perfil inativo não aparece no painel e por isso não é mexido.
    class DefinirDoUsuario
      PERMISSAO = "ti.permissoes.conceder".freeze

      def self.call(...) = new(...).call

      def initialize(user:, perfil_ids:, definido_por:)
        @user = user
        @perfil_ids = Array(perfil_ids).map(&:to_i).select(&:positive?).uniq
        @definido_por = definido_por
      end

      def call
        unless Core::Autorizacao.new(@definido_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar os perfis de abertura.", objeto: @user)
        end

        ativos = Ti::PerfilAbertura.ativo.pluck(:id)
        validos = ativos & @perfil_ids
        atuais = Ti::PerfilUsuario.where(user: @user, perfil_abertura_id: ativos).pluck(:perfil_abertura_id)
        entram = validos - atuais
        saem = atuais - validos

        Ti::PerfilUsuario.transaction do
          Ti::PerfilUsuario.where(user: @user, perfil_abertura_id: saem).destroy_all
          entram.each { |perfil_id| Ti::PerfilUsuario.create!(user: @user, perfil_abertura_id: perfil_id, concedido_por: @definido_por) }
        end

        if entram.any? || saem.any?
          Core::Api.auditar(evento: "ti.perfil_abertura.usuario_alterado", alvo: @user, ator: @definido_por, dados: { entraram: entram, sairam: saem })
        end
        Core::Resultado.sucesso(@user)
      end
    end
  end
end
