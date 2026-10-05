module Ti
  module Estatisticas
    # Estatísticas dos chamados de TI num período (porta da tela "Estatísticas" do siscom antigo: por mês,
    # tipo de problema, problema, unidade e técnico), contando os chamados pela data de abertura.
    # Vale para os chamados novos e para os migrados do siscom antigo, juntos.
    #
    #   Ti::Estatisticas::Consultar.call(filtros: { inicio: "01/01/2025", fim: "31/12/2025", categoria_id: 3, tecnico_id: 10 })
    class Consultar
      Secao = Data.define(:chave, :titulo, :colunas, :linhas)
      Resultado = Data.define(:inicio, :fim, :categoria, :tecnico, :resumo, :secoes)
      ENCERRADOS = %w[concluido finalizado].freeze
      MAIS = 20 # linhas nas seções de solicitação e de unidade

      def self.call(...) = new(...).call

      def initialize(filtros: {})
        filtros = filtros.to_h.symbolize_keys
        @fim = DataBr.interpretar(filtros[:fim]) || Date.current
        @inicio = DataBr.interpretar(filtros[:inicio]) || (@fim - 1.year + 1.day)
        @inicio, @fim = @fim, @inicio if @inicio > @fim
        @categoria = Ti::Categoria.find_by(id: filtros[:categoria_id])
        @tecnico = ::User.find_by(id: filtros[:tecnico_id])
      end

      def call
        Resultado.new(inicio: @inicio, fim: @fim, categoria: @categoria, tecnico: @tecnico, resumo: resumo,
                      secoes: [ por_mes, por_categoria, por_solicitacao, por_unidade, por_tecnico ])
      end

      private

      def chamados
        @chamados ||= begin
          escopo = Ti::Chamado.where(aberto_em: @inicio.beginning_of_day..@fim.end_of_day)
          escopo = escopo.where(problema_id: Ti::Problema.where(categoria_id: @categoria.id).select(:id)) if @categoria
          escopo = escopo.where(responsavel_id: @tecnico.id) if @tecnico
          escopo
        end
      end

      def resumo
        por_status = chamados.group(:status).count
        total = por_status.values.sum
        { "Chamados abertos no período" => total, "Atendidos (concluídos e finalizados)" => por_status.values_at(*ENCERRADOS).compact.sum,
          "Em andamento" => por_status.slice(*Ti::Chamado::EM_ANDAMENTO).values.sum, "Cancelados" => por_status.fetch("cancelado", 0),
          "Tempo médio até concluir" => duracao(chamados.where.not(concluido_em: nil).average(Arel.sql("EXTRACT(EPOCH FROM (concluido_em - aberto_em))"))),
          "Avaliação média (1 a 5)" => chamados.where.not(avaliacao: nil).average(:avaliacao)&.round(2)&.to_f || "—" }
      end

      # Mês a mês, no fuso do sistema (o banco guarda em UTC; o agrupamento é feito aqui, com a hora local).
      def por_mes
        meses = chamados.pluck(:aberto_em, :status).group_by { |aberto_em, _| aberto_em.in_time_zone.strftime("%Y-%m") }
        linhas = meses.sort.map do |chave, itens|
          status = itens.map(&:last)
          [ "#{chave[5, 2]}/#{chave[0, 4]}", itens.size, status.count { |item| ENCERRADOS.include?(item) }, status.count("cancelado") ]
        end
        Secao.new("mes", "Por mês de abertura", [ "Mês/ano", "Abertos", "Atendidos", "Cancelados" ], linhas)
      end

      def por_categoria
        contagem = chamados.joins(problema: :categoria).group("ti_categorias.nome").count
        Secao.new("categoria", "Por categoria", %w[Categoria Chamados], ordenar(contagem))
      end

      def por_solicitacao
        contagem = chamados.joins(:problema).group("ti_problemas.nome").count
        Secao.new("solicitacao", "Solicitações mais pedidas", %w[Solicitação Chamados], ordenar(contagem).first(MAIS))
      end

      def por_unidade
        contagem = chamados.group(Arel.sql("COALESCE(NULLIF(unidade_nome, ''), 'Sem unidade')")).count
        Secao.new("unidade", "Unidades que mais pediram", %w[Unidade Chamados], ordenar(contagem).first(MAIS))
      end

      def por_tecnico
        com_tecnico = chamados.where.not(responsavel_id: nil)
        total = com_tecnico.group(:responsavel_id).count
        atendidos = com_tecnico.where(status: ENCERRADOS).group(:responsavel_id).count
        tempo = com_tecnico.where.not(concluido_em: nil).group(:responsavel_id).average(Arel.sql("EXTRACT(EPOCH FROM (concluido_em - aberto_em))"))
        nota = com_tecnico.where.not(avaliacao: nil).group(:responsavel_id).average(:avaliacao)
        nomes = ::User.where(id: total.keys).pluck(:id, :nome).to_h
        linhas = total.map { |id, quantidade| [ nomes[id] || "Usuário removido", quantidade, atendidos.fetch(id, 0), duracao(tempo[id]), nota[id]&.round(2)&.to_f || "—" ] }
        Secao.new("tecnico", "Por técnico", [ "Técnico", "Chamados", "Atendidos", "Tempo médio até concluir", "Avaliação média" ], linhas.sort_by { |linha| [ -linha[1], linha[0] ] })
      end

      def ordenar(contagem) = contagem.sort_by { |nome, quantidade| [ -quantidade, nome.to_s ] }.map { |nome, quantidade| [ nome, quantidade ] }

      # "3 h 20 min", "2 dias 4 h".
      def duracao(segundos)
        return "—" if segundos.nil?

        minutos = (segundos.to_f / 60).round
        return "#{minutos} min" if minutos < 60
        return "#{minutos / 60} h #{minutos % 60} min" if minutos < 1440

        "#{minutos / 1440} dia#{'s' if minutos >= 2880} #{(minutos % 1440) / 60} h"
      end
    end
  end
end
