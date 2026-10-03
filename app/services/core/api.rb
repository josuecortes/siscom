module Core
  # Porta de entrada do Core para os outros módulos. Fora de `Core`, só estas
  # funções (e a infraestrutura pública listada em spec/support/fronteiras.rb)
  # podem ser usadas; o spec de fronteiras falha se outro módulo tocar em
  # models ou services internos do Core.
  module Api
    module_function

    # Módulos declarados em config/modulos/*.yml.
    def modulos = Catalogo.modulos

    def modulo(chave) = Catalogo.modulo(chave)

    # Notifica usuários (sino, aviso em tempo real). evento "<modulo>.<objeto>.<acao>".
    def notificar(destinatarios:, evento:, titulo:, mensagem: nil, url_acao: nil, alvo: nil, ator: :contexto, dados: {})
      Notificacoes::Criar.call(destinatarios:, evento:, titulo:, mensagem:, url_acao:, alvo:, ator:, dados:)
    end

    # Registra um evento de auditoria: evento "<modulo>.<objeto>.<acao>".
    def auditar(evento:, alvo: nil, dados: {}, ator: :contexto, descricao: nil)
      Auditoria::Registrar.call(evento:, alvo:, dados:, ator:, descricao:)
    end
  end
end
