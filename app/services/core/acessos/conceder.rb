module Core
  module Acessos
    # Concede um papel de um módulo a um usuário (com escopo opcional).
    # Conceder de novo o que já está ativo devolve a concessão existente.
    #
    #   Core::Acessos::Conceder.call(user:, modulo: "rh", papel: "operador", concedido_por: admin)
    #   Core::Acessos::Conceder.call(user:, modulo: "core", papel: "superadmin", pelo_sistema: true)
    class Conceder
      def self.call(...) = new(...).call

      def initialize(user:, modulo:, papel:, concedido_por: nil, escopo: nil, pelo_sistema: false)
        @user = user
        @modulo = modulo.to_s
        @papel = papel.to_s
        @concedido_por = concedido_por
        @escopo_tipo, @escopo_id = Core::Autorizacao.normalizar_escopo(escopo)
        @pelo_sistema = pelo_sistema
      end

      def call
        definicao = Core::Catalogo.modulo(@modulo)
        papel = definicao&.papel(@papel)
        return falha("Permissão inexistente no catálogo: #{@modulo}.#{@papel}.") unless papel
        return falha("A permissão #{papel.nome} é automática e não precisa ser concedida.") if papel.automatico?
        return falha("Usuário desativado não pode receber permissões.") unless @user.ativo?
        return falha("Você não pode conceder a permissão #{papel.nome}.") unless autorizado?

        Core::Concessao.transaction do
          acesso = Core::Acesso.find_or_create_by!(user: @user, modulo: @modulo)
          acesso.ativo! unless acesso.ativo?

          atributos = { user: @user, modulo: @modulo, papel: @papel, escopo_tipo: @escopo_tipo, escopo_id: @escopo_id }
          concessao = Core::Concessao.ativo.find_by(atributos)
          unless concessao
            concessao = Core::Concessao.create!(atributos.merge(acesso: acesso, concedido_por: @concedido_por))
            Core::Auditoria::Registrar.call(evento: "core.acesso.papel_concedido", alvo: @user, ator: @concedido_por,
                                            dados: { modulo: @modulo, papel: @papel, escopo_tipo: @escopo_tipo, escopo_id: @escopo_id }.compact)
            avisar_usuario(definicao, papel) unless @pelo_sistema
          end

          Core::Resultado.sucesso(concessao)
        end
      rescue ActiveRecord::RecordInvalid => e
        Core::Resultado.falha(e.record)
      end

      private

      def autorizado?
        @pelo_sistema || Regras.pode_conceder?(@concedido_por, modulo: @modulo, papel: @papel)
      end

      def avisar_usuario(definicao, papel)
        Core::Notificacoes::Criar.call(
          destinatarios: @user, ator: @concedido_por, evento: "core.acesso.papel_concedido", alvo: @user,
          titulo: "Você recebeu uma nova permissão",
          mensagem: "Permissão #{papel.nome} no módulo #{definicao.nome}. O menu já mostra o que mudou."
        )
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem)
    end
  end
end
