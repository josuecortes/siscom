module Rh
  module Lotacoes
    # Lota uma pessoa numa unidade com uma função (porta de hr/assignments/grant_service).
    class Lotar
      PERMISSAO = "rh.lotacoes.gerenciar".freeze

      def self.call(...) = new(...).call

      def initialize(pessoa:, atributos:, lotado_por:)
        @pessoa = pessoa
        @atributos = atributos.to_h.symbolize_keys.slice(:unidade_id, :funcao_id, :data_inicio)
        @lotado_por = lotado_por
      end

      def call
        lotacao = Rh::Lotacao.new(@atributos.merge(pessoa: @pessoa, lotado_em: Time.current, lotado_por_nome: @lotado_por&.nome,
                                                   lotado_por_email: @lotado_por&.email))
        lotacao.data_inicio ||= Date.current if @atributos[:data_inicio].blank?
        return Core::Resultado.falha("Você não pode lotar pessoas.", objeto: lotacao) unless Core::Autorizacao.new(@lotado_por).pode?(PERMISSAO)

        return Core::Resultado.falha(lotacao) unless lotacao.valid?

        lotacao.errors.add(:unidade_id, "está inativa") if lotacao.unidade&.inativo?
        lotacao.errors.add(:funcao_id, "está inativa") if lotacao.funcao&.inativo?
        return Core::Resultado.falha(lotacao) if lotacao.errors.any? || !lotacao.save

        Rh::PendenciaImportacao.abertas.where(pessoa: lotacao.pessoa, tipo: "sem_lotacao").find_each { |pendencia| pendencia.update!(resolvida_em: Time.current) }
        Core::Api.auditar(evento: "rh.lotacao.criada", alvo: @pessoa, ator: @lotado_por,
                          dados: { unidade: lotacao.unidade.sigla_e_nome, funcao: lotacao.funcao.nome })
        Core::Resultado.sucesso(lotacao)
      end
    end
  end
end
