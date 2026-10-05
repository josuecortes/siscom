module Transporte
  module Servicos
    # O motorista inicia um trecho (porta de requests/start_service.rb do seed): escolhe o veículo e
    # informa o odômetro. Regra do odômetro: não pode ser menor que o atual do veículo.
    # Solicitação aprovada → em serviço (ida); aguardando busca → o motorista sai para buscar.
    #
    # Saída em grupo (`outras_ids`): leva junto outras solicitações na mesma etapa, com o mesmo veículo
    # e odômetro. Todos os solicitantes e a operação são avisados de que o serviço é compartilhado.
    class Iniciar
      PERMISSAO = "transporte.servico.executar".freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, veiculo_id:, odometro:, outras_ids: [])
        @solicitacao = solicitacao
        @outras_ids = Array(outras_ids).map(&:to_i).select(&:positive?).uniq - [ solicitacao.id ]
        @ator = ator
        @veiculo = Transporte::Veiculo.ativo.find_by(id: veiculo_id)
        @odometro = Integer(odometro.to_s.delete("."), exception: false)
      end

      def call
        return falha("Você não pode iniciar serviços de transporte.") unless Core::Autorizacao.new(@ator).pode?(PERMISSAO)
        return falha("A solicitação precisa estar aprovada ou aguardando busca, sem serviço em andamento.") unless @solicitacao.pode_iniciar_servico?
        return falha("Veículo deve ser escolhido na lista.") unless @veiculo
        return falha("O veículo #{@veiculo.placa} já está em serviço.") if Transporte::Servico.abertos.exists?(veiculo: @veiculo)
        return falha("Odômetro inicial deve ser um número.") unless @odometro
        if @odometro < @veiculo.odometro_atual
          return falha("Odômetro inicial não pode ser menor que o atual do veículo (#{@veiculo.odometro_atual} km).")
        end

        juntas = [ @solicitacao ] + Transporte::Solicitacao.where(id: @outras_ids).order(:saida_em, :id).to_a
        unless juntas.size == @outras_ids.size + 1 && juntas.all? { |item| item.status == @solicitacao.status && item.pode_iniciar_servico? }
          return falha("Para sair em grupo, escolha só solicitações na mesma etapa e sem serviço em andamento.")
        end

        trecho = @solicitacao.busca? ? "busca" : "ida"
        grupo = SecureRandom.uuid
        Transporte::Servico.transaction do
          @veiculo.lock! # duas saídas ao mesmo tempo com o mesmo veículo: a segunda espera e é recusada
          raise ActiveRecord::RecordNotUnique, "veículo em uso" if Transporte::Servico.abertos.exists?(veiculo: @veiculo)

          juntas.each do |item|
            item.servicos.create!(trecho: trecho, motorista: @ator, motorista_nome: @ator.nome, veiculo: @veiculo, placa: @veiculo.placa,
                                  odometro_inicial: @odometro, iniciado_em: Time.current, grupo: grupo)
            item.update!(status: "em_servico") if trecho == "ida"
            outras = juntas - [ item ]
            item.registrar_evento("servico_iniciado", @ator, "#{trecho == 'ida' ? 'Saída' : 'Saída para a busca'} com o veículo #{@veiculo.placa}." \
                                                             "#{" Serviço compartilhado com #{outras.map(&:codigo).to_sentence}." if outras.any?}")
          end
          @veiculo.update!(odometro_atual: @odometro)
          Core::Api.auditar(evento: "transporte.servico.iniciado", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, trecho: trecho, placa: @veiculo.placa, odometro: @odometro,
                                     em_grupo_com: (juntas.drop(1).map(&:codigo).presence) }.compact)
        end
        avisar(juntas, trecho)
        Core::Resultado.sucesso(@solicitacao)
      rescue ActiveRecord::RecordNotUnique
        falha("Este veículo ou esta solicitação acabou de entrar em serviço por outra pessoa.")
      end

      private

      def avisar(juntas, trecho)
        titulo = trecho == "ida" ? "Seu transporte saiu" : "O motorista saiu para buscar"
        juntas.each do |item|
          outras = juntas - [ item ]
          compartilhado = outras.any? ? " Serviço compartilhado: o veículo leva também #{outras.map { |o| "#{o.codigo} (#{o.solicitante_nome})" }.to_sentence}." : ""
          Solicitacoes::Avisos.notificar(item.solicitante, item, @ator, :solicitante, (outras.any? ? "#{titulo} (serviço compartilhado)" : titulo),
                                         "#{item.codigo}: motorista #{@ator.nome}, veículo #{@veiculo.descricao}.#{compartilhado}")
          Solicitacoes::Avisos.atualizar_telas(item)
        end
        return unless juntas.size > 1

        Solicitacoes::Avisos.notificar(Solicitacoes::Avisos.operacao.to_a, @solicitacao, @ator, :operacao, "Saída em grupo",
                                       "#{@ator.nome} saiu com #{juntas.map(&:codigo).to_sentence} no veículo #{@veiculo.placa}.")
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
