module Core
  module Acessos
    # Revoga uma concessão (fica inativa, como histórico). Nunca deixa o
    # sistema sem um superadministrador ativo.
    class Revogar
      def self.call(...) = new(...).call

      def initialize(concessao:, revogado_por: nil, pelo_sistema: false)
        @concessao = concessao
        @revogado_por = revogado_por
        @pelo_sistema = pelo_sistema
      end

      def call
        return Core::Resultado.sucesso(@concessao) if @concessao.inativo?
        return falha("Você não pode revogar este papel.") unless autorizado?
        return falha("Não é possível revogar o último superadministrador ativo.") if ultimo_superadmin?

        @concessao.inativo!
        Core::Resultado.sucesso(@concessao)
      end

      private

      def autorizado?
        @pelo_sistema || Regras.pode_conceder?(@revogado_por, modulo: @concessao.modulo, papel: @concessao.papel)
      end

      def ultimo_superadmin?
        return false unless @concessao.modulo == "core" && @concessao.papel == "superadmin"

        Core::Concessao.ativo.where(modulo: "core", papel: "superadmin")
                       .where.not(user_id: @concessao.user_id)
                       .joins(:user).merge(::User.ativos)
                       .joins(:acesso).merge(Core::Acesso.ativo)
                       .none?
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @concessao)
    end
  end
end
