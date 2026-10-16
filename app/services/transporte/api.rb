module Transporte
  # Porta de entrada do Transporte para os outros módulos. Fora de `Transporte`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades do Transporte que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")

    # Tela Início: o que a pessoa tem no Transporte (mesmo formato de Ti::Api.resumo_do_inicio).
    def resumo_do_inicio(user)
      rotas = Rails.application.routes.url_helpers
      pode = Core::Autorizacao.new(user)
      abre = pode.pode?(Transporte::Solicitacoes::Abrir::PERMISSAO)
      opera = pode.pode?("transporte.solicitacoes.operar")
      return nil unless abre || opera

      minhas = Transporte::Solicitacao.where(solicitante: user)
      atencao = [ { titulo: "Reagendamento de transporte para responder", detalhe: "A operação propôs outro horário: aceite ou recuse.",
                    quantidade: minhas.where(status: "reagendada").count, caminho: rotas.transporte_solicitacoes_path(status: "reagendada"), tom: "atencao" } ]
      abertas = minhas.em_andamento.order(:saida_em, :id)
      itens = abertas.limit(5).map do |solicitacao|
        { codigo: solicitacao.codigo, titulo: solicitacao.resumo.to_s.truncate(70), etapa: solicitacao.nome_do_status, caminho: rotas.transporte_solicitacao_path(solicitacao),
          detalhe: "Saída #{I18n.l(solicitacao.saida_em, format: '%d/%m/%Y %H:%M')}" }
      end
      { atalhos: (abre ? [ { rotulo: "Nova solicitação de transporte", caminho: rotas.new_transporte_solicitacao_path, icone: "car-alt", painel: true } ] : []),
        atencao: atencao, andamento: (abre ? { titulo: "Minhas solicitações de transporte", itens: itens, total: abertas.count, todos: rotas.transporte_solicitacoes_path } : nil),
        operacao: (opera ? operacao_do_inicio(pode, rotas) : nil) }
    end

    def operacao_do_inicio(pode, rotas)
      hoje = Time.zone.today.all_day
      { titulo: "Operação do Transporte",
        numeros: [ { rotulo: "esperando aprovação", quantidade: Transporte::Solicitacao.where(status: "solicitada").count },
                   { rotulo: "saídas aprovadas para hoje", quantidade: Transporte::Solicitacao.where(status: "aprovada", saida_em: hoje).count } ],
        links: [ { rotulo: "Abrir a Operação", caminho: rotas.transporte_operacao_index_path },
                 ({ rotulo: "Acompanhamento", caminho: rotas.transporte_sobre_acompanhamento_path } if pode.pode?("transporte.acompanhamento.ver")) ].compact }
    end
  end
end
