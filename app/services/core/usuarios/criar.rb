module Core
  module Usuarios
    # Cadastra um usuário com a senha padrão das Configurações (ou, se não houver, uma temporária aleatória),
    # devolvida em `user.senha_temporaria` para mostrar a quem cadastrou, e troca obrigatória no primeiro acesso.
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

        temporaria = Core::PoliticaDeSenha.senha_inicial
        user = ::User.new(@atributos.merge(password: temporaria, password_confirmation: temporaria, senha_definida_pela_administracao: true,
                                           status: true, deve_trocar_senha: true))
        return Core::Resultado.falha(user) unless user.save

        user.senha_temporaria = temporaria
        Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: user, ator: @criado_por, dados: { email: user.email })
        Core::Resultado.sucesso(user)
      end

      private

      def autorizado?
        @pelo_sistema || (@criado_por && Core::Autorizacao.new(@criado_por).pode?(PERMISSAO))
      end
    end
  end
end
