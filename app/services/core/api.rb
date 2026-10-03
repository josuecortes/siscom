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

    # --- Contas (para o RH ligar pessoa ↔ conta) ---

    def conta_por_email(email) = ::User.find_by(email: email.to_s.strip.downcase)

    # Cria a conta de uma pessoa cadastrada por outro módulo. Devolve Core::Resultado com o
    # usuário; a senha temporária fica em `objeto.senha_temporaria` (mostrar uma única vez).
    def criar_conta(nome:, email:, criado_por:)
      Usuarios::Criar.call(atributos: { nome:, email: }, criado_por:, pelo_sistema: true)
    end

    # Mantém nome e e-mail da conta iguais aos da pessoa.
    def sincronizar_conta(user, nome:, email:, atualizado_por:)
      return Resultado.sucesso(user) if user.nome == nome.to_s.squish.upcase && user.email == email.to_s.strip.downcase
      return Resultado.falha(user) unless user.update(nome:, email:)

      mudancas = user.saved_changes.slice("nome", "email").transform_values { |de, para| { de: de, para: para } }
      auditar(evento: "core.usuario.atualizado", alvo: user, ator: atualizado_por, dados: { mudancas: mudancas, origem: "rh" })
      Resultado.sucesso(user)
    end

    # Opções de uma fonte de referência para campos de busca/seleção:
    # [{ valor:, rotulo:, subtitulo: }]
    def opcoes_da_fonte(chave, termo: nil, limite: FontesReferencia::Consultar::LIMITE)
      FontesReferencia::Consultar.call(chave:, termo:, limite:)
    end

    # Entidades do Core que podem virar fonte de referência (ver Core::FontesReferencia::Entidades).
    def entidades_publicaveis
      {
        "usuarios" => {
          nome: "Administração > Usuários", descricao: "Usuários ativos do sistema.",
          campo_rotulo: "nome", campo_valor: "id", campo_subtitulo: "email",
          campos_busca: %w[nome email], campos: %w[id nome email]
        }
      }
    end

    def registros_da_entidade(entidade)
      case entidade.to_s
      when "usuarios" then ::User.ativos
      else raise ArgumentError, "entidade desconhecida: #{entidade}"
      end
    end

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
