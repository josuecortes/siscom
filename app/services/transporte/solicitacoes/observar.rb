module Transporte
  module Solicitacoes
    # Registra uma observação com anexos (porta de create_observation do seed): a operação em
    # qualquer solicitação; o motorista só nas que ele atendeu.
    class Observar
      def self.call(...) = new(...).call

      def self.papel_de(solicitacao, user)
        return "tecnico" if Core::Autorizacao.new(user).pode?(Reagendar::PERMISSAO)

        "motorista" if solicitacao.servicos.exists?(motorista: user)
      end

      def initialize(solicitacao:, ator:, corpo:, anexos: [])
        @solicitacao = solicitacao
        @ator = ator
        @corpo = corpo
        @anexos = (anexos.is_a?(Array) ? anexos : [ anexos ]).select { |item| item.respond_to?(:original_filename) }
      end

      def call
        papel = self.class.papel_de(@solicitacao, @ator)
        return Core::Resultado.falha("Você não pode registrar observações nesta solicitação.") unless papel
        return Core::Resultado.falha("Cada anexo pode ter no máximo 10 MB.") if @anexos.any? { |anexo| anexo.size > Transporte::Observacao::TAMANHO_MAXIMO }

        observacao = @solicitacao.observacoes.new(autor: @ator, autor_nome: @ator.nome, papel: papel, corpo: @corpo)
        return Core::Resultado.falha(observacao) unless observacao.save

        observacao.anexos.attach(@anexos) if @anexos.any?
        Core::Api.auditar(evento: "transporte.solicitacao.observada", alvo: @solicitacao, ator: @ator, dados: { codigo: @solicitacao.codigo })
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(observacao)
      end
    end
  end
end
