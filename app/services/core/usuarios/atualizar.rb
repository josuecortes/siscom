module Core
  module Usuarios
    # Atualiza os dados de identificação (nome e e-mail) de um usuário.
    class Atualizar
      def self.call(...) = new(...).call

      def initialize(user:, atributos:, atualizado_por:)
        @user = user
        @atributos = atributos.to_h.symbolize_keys.slice(:nome, :email)
        @atualizado_por = atualizado_por
      end

      def call
        unless Core::Autorizacao.new(@atualizado_por).pode?(Criar::PERMISSAO)
          return Core::Resultado.falha("Você não pode editar usuários.", objeto: @user)
        end

        @user.update(@atributos) ? Core::Resultado.sucesso(@user) : Core::Resultado.falha(@user)
      end
    end
  end
end
