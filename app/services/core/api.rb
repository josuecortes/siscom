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

    # --- Papéis (para a tela de acessos de cada módulo) ---

    # { user_id => ["operador", ...] }: papéis concedidos (sem os automáticos) no módulo.
    def papeis_concedidos(user_ids, modulo:)
      Concessao.ativo.where(user_id: user_ids, modulo: modulo.to_s, escopo_id: nil).order(:papel)
               .pluck(:user_id, :papel).group_by(&:first).transform_values { |linhas| linhas.map(&:last) }
    end

    # Ids (como subconsulta) dos usuários com algum papel concedido no módulo.
    # Com `papeis`, só os que têm algum deles (ex.: quem avisar quando chega um pedido).
    def ids_dos_usuarios_com_papel(modulo:, papeis: nil)
      concessoes = Concessao.ativo.where(modulo: modulo.to_s)
      concessoes = concessoes.where(papel: Array(papeis).map(&:to_s)) if papeis
      concessoes.select(:user_id)
    end

    # Deixa o usuário com um único papel no módulo (ou nenhum, com papel em branco):
    # revoga os outros e concede o escolhido. Vale a regra de quem pode conceder.
    def definir_papel(user:, modulo:, papel:, definido_por:)
      definir_papeis(user:, modulo:, papeis: [ papel ], definido_por:)
    end

    # Deixa o usuário exatamente com os papéis informados no módulo (módulos em que a pessoa
    # acumula papéis, ex.: triador e técnico na TI): revoga os que saíram e concede os novos.
    def definir_papeis(user:, modulo:, papeis:, definido_por:)
      papeis = Array(papeis).map(&:to_s).compact_blank.uniq
      atuais = Concessao.ativo.where(user: user, modulo: modulo.to_s, escopo_id: nil).to_a
      novos = papeis - atuais.map(&:papel)
      if novos.any? { |papel| !Acessos::Regras.pode_conceder?(definido_por, modulo:, papel:) }
        return Resultado.falha("Você não pode conceder esta permissão.")
      end

      falha = nil
      Concessao.transaction do
        falha = atuais.reject { |concessao| papeis.include?(concessao.papel) }
                      .lazy.map { |concessao| Acessos::Revogar.call(concessao: concessao, revogado_por: definido_por) }.find(&:falha?)
        falha ||= novos.lazy.map { |papel| Acessos::Conceder.call(user: user, modulo: modulo, papel: papel, concedido_por: definido_por) }.find(&:falha?)
        raise ActiveRecord::Rollback if falha
      end
      falha || Resultado.sucesso(user)
    end

    # Converte papéis antigos (Rolify) em concessões: { "papel_antigo" => [["modulo", "papel_novo"]] }. Idempotente.
    def importar_papeis(mapa) = Importacao::Papeis.call(mapa)

    # Concessão feita pelo sistema (carga inicial, migração): não passa pela regra de quem pode conceder. Idempotente.
    def conceder_pelo_sistema(user:, modulo:, papel:) = Acessos::Conceder.call(user: user, modulo: modulo, papel: papel, pelo_sistema: true)

    def pode_conceder?(user, modulo:, papel:) = Acessos::Regras.pode_conceder?(user, modulo:, papel:)

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

    # A opção da fonte com aquele valor ({ valor:, rotulo:, subtitulo: }) ou nil.
    def opcao_da_fonte(chave, valor)
      return nil if valor.blank?

      FontesReferencia::Consultar.call(chave:, valor: valor, limite: 1).first
    end

    # Fontes de referência ativas, para quem monta formulários: [#<chave, nome>].
    FonteDisponivel = Data.define(:chave, :nome)

    def fontes_de_referencia
      publicar_fontes_padrao unless FonteReferencia.exists? # banco novo
      FonteReferencia.ativo.ordenadas.pluck(:chave, :nome).map { |chave, nome| FonteDisponivel.new(chave:, nome:) }
    end

    # Publica (ou atualiza) a fonte padrão de cada entidade publicável dos módulos. Idempotente.
    def publicar_fontes_padrao = FontesReferencia::Publicar.call

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

    # --- Conversas (chat ligado a um registro do módulo) ---

    # Cria/atualiza a conversa do registro: ativa ou só leitura, participantes atuais e nota do sistema.
    # participantes: [{ user:, papel:, url: }] (url = onde aquele participante vê a conversa).
    def sincronizar_conversa(alvo:, modulo:, titulo:, ativa:, participantes:, motivo_leitura: nil, nota_do_sistema: nil)
      Conversas::Sincronizar.call(alvo:, modulo:, titulo:, ativa:, participantes:, motivo_leitura:, nota_do_sistema:)
    end

    # Importa a conversa antiga de um registro (migração do siscom antigo): cria a conversa só para leitura,
    # com as mensagens nas datas originais, já lidas, sem avisar ninguém. Não faz nada se o registro já tem conversa.
    #   participantes: [{ user:, papel:, url: }]   mensagens: [{ autor:, corpo:, em: }]
    def importar_conversa(alvo:, modulo:, titulo:, participantes:, mensagens:, motivo_leitura: nil)
      Conversas::Importar.call(alvo:, modulo:, titulo:, participantes:, mensagens:, motivo_leitura:)
    end

    # A conversa do registro (ou nil), para renderizar com `core/conversas/conversa`.
    def conversa_de(alvo) = Conversa.de(alvo)

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
