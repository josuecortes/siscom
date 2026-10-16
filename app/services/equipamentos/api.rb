module Equipamentos
  # Porta de entrada de Equipamentos para os outros módulos. Fora de `Equipamentos`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")

    # Tela Início: o que a pessoa tem para receber, aceitar, devolver ou receber de volta (mesmo formato de Ti::Api.resumo_do_inicio).
    def resumo_do_inicio(user)
      rotas = Rails.application.routes.url_helpers
      return nil unless Core::Autorizacao.new(user).pode?("equipamentos.receber")

      para_mim = Equipamentos::ItemMovimentacao.joins(:movimentacao).where(equipamentos_movimentacoes: { responsavel_id: user.id, status: "em_andamento" })
      receber = para_mim.pendente.count + Equipamentos::ItemMovimentacao.devolucao_pendente.where(devolver_para: user).count
      atrasados = Equipamentos::Movimentacao.emprestimos.em_andamento.where(responsavel: user).where.not(aceita_em: nil).where(previsao_devolucao: ...Date.current).count
      { atalhos: [ { rotulo: "Meus equipamentos", caminho: rotas.equipamentos_recebimentos_path, icone: "briefcase", painel: false } ],
        atencao: [ { titulo: "Equipamentos para receber", detalhe: "Envios, termos de empréstimo ou devoluções esperando você.", quantidade: receber,
                     caminho: rotas.equipamentos_recebimentos_path, tom: "atencao" },
                   { titulo: "Devolução de equipamento atrasada", detalhe: "Empréstimo ou cautela com a data de devolução vencida.", quantidade: atrasados,
                     caminho: rotas.equipamentos_recebimentos_path(aba: "comigo"), tom: "perigo" } ],
        andamento: nil, operacao: nil }
    end
  end
end
