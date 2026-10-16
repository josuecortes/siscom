module Ti
  # Porta de entrada da TI para os outros módulos. Fora de `Ti`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades da TI que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")

    # Tela Início: o que a pessoa tem na TI. Devolve
    #   { atalhos: [{ rotulo:, caminho:, icone:, painel: }], atencao: [{ titulo:, detalhe:, quantidade:, caminho:, tom: }],
    #     andamento: { titulo:, itens: [{ codigo:, titulo:, etapa:, detalhe:, caminho: }], total:, todos: }, operacao: {...} ou nil }
    def resumo_do_inicio(user)
      rotas = Rails.application.routes.url_helpers
      pode = Core::Autorizacao.new(user)
      return nil unless pode.pode?(Ti::Chamados::Abrir::PERMISSAO) || Ti::Chamados::Acesso.opera?(user)

      meus = Ti::Chamado.where(solicitante: user)
      atencao = [
        { titulo: "Chamados de TI para finalizar", detalhe: "A TI concluiu: confira e finalize, com a sua avaliação.", quantidade: meus.where(status: "concluido").count,
          caminho: rotas.ti_chamados_path(status: "concluido"), tom: "atencao" },
        { titulo: "Chamados de TI para ajustar", detalhe: "A TI pediu um ajuste na sua solicitação.", quantidade: meus.where(status: "aguardando_solicitante").count,
          caminho: rotas.ti_chamados_path(status: "aguardando_solicitante"), tom: "atencao" }
      ]
      abertos = meus.em_andamento.recentes.includes(:problema, :responsavel)
      itens = abertos.limit(5).map do |chamado|
        { codigo: chamado.codigo, titulo: chamado.problema.nome, etapa: chamado.nome_do_status, caminho: rotas.ti_chamado_path(chamado),
          detalhe: chamado.responsavel ? "Com #{chamado.responsavel.nome}" : "Aguardando técnico" }
      end
      { atalhos: (pode.pode?(Ti::Chamados::Abrir::PERMISSAO) ? [ { rotulo: "Abrir chamado de TI", caminho: rotas.new_ti_chamado_path, icone: "task", painel: true } ] : []),
        atencao: atencao, andamento: { titulo: "Meus chamados de TI", itens: itens, total: abertos.count, todos: rotas.ti_chamados_path },
        operacao: operacao_do_inicio(user, pode, rotas) }
    end

    # Para quem trabalha na Operação: a fila dos seus grupos (sem técnico) e o que está com a pessoa.
    def operacao_do_inicio(user, pode, rotas)
      return nil unless Ti::Chamados::Acesso.opera?(user)

      visiveis = Ti::Chamados::Acesso.visiveis(user)
      { titulo: "Operação da TI",
        numeros: [ { rotulo: "esperando atendimento", quantidade: visiveis.where(status: %w[aberto aguardando_tecnico], responsavel_id: nil).count },
                   { rotulo: "com você", quantidade: visiveis.em_andamento.where(responsavel: user).count } ],
        links: [ { rotulo: "Abrir a Operação", caminho: rotas.ti_operacao_index_path },
                 ({ rotulo: "Acompanhamento", caminho: rotas.ti_sobre_acompanhamento_path } if pode.pode?("ti.acompanhamento.ver")) ].compact }
    end
  end
end
