module Rh
  module Lotacoes
    # Encerra uma lotação (porta de hr/assignments/revoke_service): fecha a data de fim e
    # guarda quem encerrou. O registro fica como histórico.
    class Encerrar
      def self.call(...) = new(...).call

      def initialize(lotacao:, encerrado_por:, data_fim: nil)
        @lotacao = lotacao
        @encerrado_por = encerrado_por
        @data_fim = DataBr.interpretar(data_fim) || Date.current
      end

      def call
        return falha("Você não pode encerrar lotações.") unless Core::Autorizacao.new(@encerrado_por).pode?(Lotar::PERMISSAO)
        return Core::Resultado.sucesso(@lotacao) if @lotacao.inativo?

        atualizou = @lotacao.update(status: "inativo", data_fim: [ @data_fim, @lotacao.data_inicio ].max, encerrado_em: Time.current,
                                    encerrado_por_nome: @encerrado_por.nome, encerrado_por_email: @encerrado_por.email)
        return Core::Resultado.falha(@lotacao) unless atualizou

        Core::Api.auditar(evento: "rh.lotacao.encerrada", alvo: @lotacao.pessoa, ator: @encerrado_por,
                          dados: { unidade: @lotacao.unidade.sigla_e_nome, funcao: @lotacao.funcao.nome })
        Core::Resultado.sucesso(@lotacao)
      end

      private

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @lotacao)
    end
  end
end
