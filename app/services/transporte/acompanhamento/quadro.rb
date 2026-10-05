module Transporte
  module Acompanhamento
    # O quadro do painel de TV: as solicitações por etapa, cada uma com o nível de urgência e o aviso
    # que explica por que ela pede atenção. Em cada coluna, o mais urgente vem primeiro.
    #
    # Níveis (do mais grave para o mais calmo): critico (passou da hora: alguém está esperando ou
    # ficou sem resposta), urgente (falta pouco), atencao (convém olhar), normal.
    class Quadro
      NIVEIS = %w[critico urgente atencao normal].freeze
      Item = Data.define(:codigo, :nome, :detalhe, :horario, :nivel, :aviso)
      Coluna = Data.define(:chave, :titulo, :vazio, :itens)

      # Minutos até a hora marcada que mudam o nível (pedido sem aprovação, saída aprovada, busca).
      SEM_APROVACAO = { urgente: 120, atencao: 24 * 60 }.freeze
      SAIDA = { urgente: 60, atencao: 120 }.freeze
      BUSCA = { urgente: 30, atencao: 60 }.freeze
      # Em andamento: quanto tempo um trecho costuma levar sem contar a espera, e a folga antes de virar
      # crítico (provável esquecimento de registrar a chegada).
      TRECHO_PADRAO = 2.hours
      FOLGA = 2.hours

      attr_reader :agora

      def initialize(agora: Time.current)
        @agora = agora
      end

      def colunas
        @colunas ||= [
          Coluna.new("aprovacao", "Aguardando aprovação", "Nenhuma solicitação aguardando.", ordenar(sem_aprovacao)),
          Coluna.new("saidas", "Saídas aprovadas", "Nenhuma saída programada.", ordenar(saidas)),
          Coluna.new("andamento", "Em andamento", "Nenhum veículo em serviço.", ordenar(em_andamento)),
          Coluna.new("buscas", "Aguardando busca", "Ninguém aguardando busca.", ordenar(buscas))
        ]
      end

      # Quantos itens em cada nível, no quadro todo (para o resumo do cabeçalho).
      def contagem = colunas.flat_map(&:itens).map(&:nivel).tally

      private

      def abertos = @abertos ||= Transporte::Servico.abertos.includes(:solicitacao).order(:iniciado_em).to_a

      # Pedidos sem resposta: os que a operação ainda não aprovou e os reagendados que o solicitante não respondeu.
      def sem_aprovacao
        Transporte::Solicitacao.where(status: %w[solicitada reagendada]).order(:saida_em).limit(40).map do |s|
          minutos = minutos_ate(s.saida_em)
          quem = s.reagendada? ? "sem resposta do solicitante ao reagendamento" : "sem aprovação"
          nivel, aviso =
            if minutos.negative? then [ "critico", "A saída era #{quando(minutos)} e está #{quem}" ]
            elsif minutos <= SEM_APROVACAO[:urgente] then [ "urgente", "Sai #{quando(minutos)} e está #{quem}" ]
            elsif minutos <= SEM_APROVACAO[:atencao] then [ "atencao", "Sai #{quando(minutos)}, #{quem}" ]
            else [ "normal", (s.reagendada? ? "Reagendada: aguardando o solicitante" : nil) ]
            end
          Item.new(s.codigo, s.solicitante_nome, s.unidade_nome.presence || s.nome_do_tipo, s.saida_em, nivel, aviso)
        end
      end

      # Aprovadas que ainda não saíram: todas as atrasadas e as que saem até o fim de amanhã.
      def saidas
        Transporte::Solicitacao.aprovada.where(saida_em: ..(agora.end_of_day + 1.day)).order(:saida_em).limit(40).map do |s|
          minutos = minutos_ate(s.saida_em)
          nivel, aviso =
            if minutos.negative? then [ "critico", "Devia ter saído #{quando(minutos)}: nenhum motorista iniciou" ]
            elsif minutos <= SAIDA[:urgente] then [ "urgente", "Sai #{quando(minutos)}" ]
            elsif minutos <= SAIDA[:atencao] then [ "atencao", "Sai #{quando(minutos)}" ]
            else [ "normal", nil ]
            end
          Item.new(s.codigo, s.solicitante_nome, [ s.nome_do_modo, s.unidade_nome.presence ].compact.join(" · "), s.saida_em, nivel, aviso)
        end
      end

      # Trechos em andamento. Passou do tempo previsto: atenção; passou muito: o motorista pode ter
      # esquecido de registrar a chegada.
      def em_andamento
        abertos.map do |servico|
          s = servico.solicitacao
          passou = ((agora - previsao_de_chegada(servico)) / 60).floor
          nivel, aviso =
            if passou > FOLGA / 60 then [ "critico", "Sem chegada registrada #{duracao(passou)} depois do previsto: confirmar com o motorista" ]
            elsif passou.positive? then [ "atencao", "Passou #{duracao(passou)} do tempo previsto" ]
            else [ "normal", "Na rua há #{duracao(((agora - servico.iniciado_em) / 60).floor)}" ]
            end
          Item.new(s.codigo, s.solicitante_nome, "#{servico.nome_do_trecho} · #{servico.motorista_nome} · #{servico.placa}", servico.iniciado_em, nivel, aviso)
        end
      end

      def previsao_de_chegada(servico)
        s = servico.solicitacao
        return [ s.retorno_em, servico.iniciado_em + TRECHO_PADRAO ].max if s.viagem? && s.retorno_em && servico.de_ida?

        servico.iniciado_em + TRECHO_PADRAO + (servico.de_ida? && s.esperar_no_local? ? s.espera_horas.to_i.hours : 0)
      end

      # Deixados no destino, esperando o motorista voltar (os que já têm motorista a caminho estão em "Em andamento").
      def buscas
        Transporte::Solicitacao.busca.where.not(id: abertos.map(&:solicitacao_id)).order(:busca_prevista_em).limit(40).map do |s|
          minutos = s.busca_prevista_em ? minutos_ate(s.busca_prevista_em) : nil
          nivel, aviso =
            if minutos.nil? then [ "atencao", "Sem hora de busca definida" ]
            elsif minutos.negative? then [ "critico", "Esperando a busca #{quando(minutos)}: ninguém saiu para buscar" ]
            elsif minutos <= BUSCA[:urgente] then [ "urgente", "Buscar #{quando(minutos)}" ]
            elsif minutos <= BUSCA[:atencao] then [ "atencao", "Buscar #{quando(minutos)}" ]
            else [ "normal", nil ]
            end
          Item.new(s.codigo, s.solicitante_nome, s.unidade_nome.presence || "Busca", s.busca_prevista_em, nivel, aviso)
        end
      end

      def ordenar(itens) = itens.sort_by.with_index { |item, indice| [ NIVEIS.index(item.nivel), indice ] }

      def minutos_ate(momento) = ((momento - agora) / 60).round

      # "em 45 min", "há 2 h 10 min", "há 2 dias".
      def quando(minutos) = minutos.negative? ? "há #{duracao(-minutos)}" : "em #{duracao(minutos)}"

      def duracao(minutos)
        return "menos de 1 min" if minutos < 1
        return "#{minutos} min" if minutos < 60
        return "#{minutos / 1440} dia#{'s' if minutos >= 2880}" if minutos >= 1440

        resto = minutos % 60
        resto.zero? ? "#{minutos / 60} h" : "#{minutos / 60} h #{resto} min"
      end
    end
  end
end
