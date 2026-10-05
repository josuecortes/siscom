module Transporte
  module Servicos
    # O motorista inicia um trecho (porta de requests/start_service.rb do seed): escolhe o veículo e
    # informa o odômetro. Regra do odômetro: não pode ser menor que o atual do veículo.
    # Solicitação aprovada → em serviço (ida); aguardando busca → o motorista sai para buscar.
    class Iniciar
      PERMISSAO = "transporte.servico.executar".freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, veiculo_id:, odometro:)
        @solicitacao = solicitacao
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

        trecho = @solicitacao.busca? ? "busca" : "ida"
        Transporte::Servico.transaction do
          @solicitacao.servicos.create!(trecho: trecho, motorista: @ator, motorista_nome: @ator.nome, veiculo: @veiculo, placa: @veiculo.placa,
                                        odometro_inicial: @odometro, iniciado_em: Time.current)
          @veiculo.update!(odometro_atual: @odometro)
          @solicitacao.update!(status: "em_servico") if trecho == "ida"
          Core::Api.auditar(evento: "transporte.servico.iniciado", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, trecho: trecho, placa: @veiculo.placa, odometro: @odometro })
        end
        Solicitacoes::Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante,
                                       (trecho == "ida" ? "Seu transporte saiu" : "O motorista saiu para buscar"),
                                       "#{@solicitacao.codigo}: motorista #{@ator.nome}, veículo #{@veiculo.descricao}.")
        Solicitacoes::Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      rescue ActiveRecord::RecordNotUnique
        falha("Este veículo ou esta solicitação acabou de entrar em serviço por outra pessoa.")
      end

      private

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
