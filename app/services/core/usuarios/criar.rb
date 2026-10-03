module Core
  module Usuarios
    # Cadastra um usuário com senha temporária aleatória (em `user.senha_temporaria`,
    # mostrada uma única vez a quem cadastrou) e troca obrigatória no primeiro acesso.
    class Criar
      PERMISSAO = "core.usuarios.gerenciar".freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, criado_por: nil, pelo_sistema: false)
        @atributos = atributos.to_h.symbolize_keys.slice(:nome, :email)
        @criado_por = criado_por
        @pelo_sistema = pelo_sistema
      end

      def call
        return Core::Resultado.falha("Você não pode cadastrar usuários.") unless autorizado?

        temporaria = Core::PoliticaDeSenha.gerar_temporaria
        user = ::User.new(@atributos.merge(password: temporaria, password_confirmation: temporaria,
                                           status: true, deve_trocar_senha: true))
        return Core::Resultado.falha(user) unless user.save

        user.senha_temporaria = temporaria
        Core::Resultado.sucesso(user)
      end

      private

      def autorizado?
        @pelo_sistema || (@criado_por && Core::Autorizacao.new(@criado_por).pode?(PERMISSAO))
      end
    end
  end
end
