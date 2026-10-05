module Ti
  module Acompanhamento
    # O quadro do painel de TV da TI: os chamados em andamento por etapa, cada um com o nível de urgência
    # e o aviso que explica por que ele pede atenção (peças comuns em PainelTv). Em cada coluna, o mais
    # urgente vem primeiro.
    #
    # A urgência vem do tempo parado na etapa, e o limite depende da prioridade do chamado: quanto mais
    # alta, menos tempo ele pode esperar. Conta o tempo corrido (não desconta noite nem fim de semana).
    class Quadro
      # Minutos na etapa para virar [atenção, urgente, crítico], por prioridade.
      SEM_RESPONSAVEL = { "critica" => [ 15, 30, 60 ], "urgente" => [ 30, 60, 120 ], "alta" => [ 60, 120, 240 ], "normal" => [ 120, 240, 480 ] }.freeze
      EM_ATENDIMENTO = { "critica" => [ 60, 120, 240 ], "urgente" => [ 120, 240, 480 ], "alta" => [ 240, 480, 1440 ], "normal" => [ 480, 1440, 4320 ] }.freeze
      # Parado esperando o solicitante ou com impedimento: 1, 2 e 3 dias, em qualquer prioridade.
      PARADO = [ 1440, 2880, 4320 ].freeze
      LIMITE = 60

      attr_reader :agora

      def initialize(agora: Time.current)
        @agora = agora
      end

      def colunas
        @colunas ||= [
          coluna("espera", "Aguardando atendimento", "Nenhum chamado esperando.", %w[aberto aguardando_tecnico]) { |c| sem_responsavel(c) },
          coluna("triagem", "Em triagem", "Nenhum chamado em triagem.", %w[em_triagem]) { |c| em_triagem(c) },
          coluna("atendimento", "Em atendimento", "Nenhum chamado em atendimento.", %w[em_atendimento]) { |c| em_atendimento(c) },
          coluna("parados", "Parados", "Nenhum chamado parado.", %w[aguardando_solicitante impedido]) { |c| parado(c) }
        ]
      end

      def contagem = PainelTv.contagem(colunas)

      private

      def coluna(chave, titulo, vazio, status)
        chamados = Ti::Chamado.where(status: status).includes(:problema, :responsavel, :triador)
                              .order(Arel.sql(Ti::Chamado::ORDEM_DE_PRIORIDADE), :aberto_em, :id).limit(LIMITE)
        PainelTv::Coluna.new(chave, titulo, vazio, PainelTv.ordenar(chamados.map { |chamado| item(chamado, *yield(chamado)) }))
      end

      def item(chamado, nivel, aviso)
        prioridade = chamado.prioridade_normal? ? nil : chamado.nome_da_prioridade.upcase
        PainelTv::Item.new(codigo: chamado.codigo, nome: chamado.solicitante_nome, unidade: chamado.unidade_nome, detalhe: [ prioridade, chamado.problema.nome ].compact.join(" · "),
                           responsaveis: responsaveis(chamado), horario: chamado.aberto_em, nivel:, aviso:)
      end

      # Quem está (ou esteve) triando e quem está atendendo.
      def responsaveis(chamado)
        [ ("Triagem: #{PainelTv.nome_curto(chamado.triador.nome)}" if chamado.triador),
          ("Técnico: #{PainelTv.nome_curto(chamado.responsavel.nome)}" if chamado.responsavel) ].compact.join(" · ")
      end

      # Aberto, ou triado e esperando um técnico: ninguém está cuidando.
      def sem_responsavel(chamado)
        desde = chamado.aguardando_tecnico? ? (chamado.triado_em || chamado.aberto_em) : chamado.aberto_em
        minutos = desde_ha(desde)
        o_que = chamado.aguardando_tecnico? ? "Triado, sem técnico" : "Sem responsável"
        [ nivel(minutos, SEM_RESPONSAVEL.fetch(chamado.prioridade)), "#{o_que} há #{PainelTv.duracao(minutos)}" ]
      end

      def em_triagem(chamado)
        minutos = desde_ha(chamado.triado_em || chamado.updated_at)
        [ nivel(minutos, SEM_RESPONSAVEL.fetch(chamado.prioridade)), "Em triagem há #{PainelTv.duracao(minutos)}" ]
      end

      def em_atendimento(chamado)
        minutos = desde_ha(chamado.updated_at)
        [ nivel(minutos, EM_ATENDIMENTO.fetch(chamado.prioridade)), "Em atendimento há #{PainelTv.duracao(minutos)}, sem novidade" ]
      end

      def parado(chamado)
        minutos = desde_ha(chamado.updated_at)
        motivo = chamado.impedido? ? "Impedido" : "Esperando o solicitante"
        [ nivel(minutos, PARADO), "#{motivo} há #{PainelTv.duracao(minutos)}" ]
      end

      def desde_ha(momento) = -PainelTv.minutos_ate(momento, agora)

      def nivel(minutos, (atencao, urgente, critico))
        if minutos >= critico then "critico"
        elsif minutos >= urgente then "urgente"
        elsif minutos >= atencao then "atencao"
        else "normal"
        end
      end
    end
  end
end
