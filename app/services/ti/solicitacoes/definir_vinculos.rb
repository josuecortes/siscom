module Ti
  module Solicitacoes
    # Deixa a solicitação exatamente com os perfis de abertura (quem abre) ou os grupos
    # técnicos (quem atende) informados. Itens inativos não aparecem no painel e não são mexidos.
    class DefinirVinculos
      TIPOS = {
        "perfis" => { modelo: "Ti::PerfilAbertura", vinculos: :vinculos_de_perfil, chave: :perfil_abertura_id, evento: "perfis_alterados" },
        "grupos" => { modelo: "Ti::GrupoTecnico", vinculos: :vinculos_de_grupo, chave: :grupo_tecnico_id, evento: "grupos_alterados" }
      }.freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, tipo:, ids:, definido_por:)
        @solicitacao = solicitacao
        @tipo = TIPOS.fetch(tipo.to_s)
        @ids = Array(ids).map(&:to_i).select(&:positive?).uniq
        @definido_por = definido_por
      end

      def call
        unless Core::Autorizacao.new(@definido_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @solicitacao)
        end

        chave = @tipo[:chave]
        vinculos = @solicitacao.public_send(@tipo[:vinculos])
        ativos = modelo.ativo.pluck(:id)
        atuais = vinculos.where(chave => ativos).pluck(chave)
        entram = (ativos & @ids) - atuais
        saem = atuais - @ids

        @solicitacao.transaction do
          vinculos.where(chave => saem).destroy_all
          entram.each { |id| vinculos.create!(chave => id) }
        end

        if entram.any? || saem.any?
          Core::Api.auditar(evento: "ti.solicitacao.#{@tipo[:evento]}", alvo: @solicitacao, ator: @definido_por, dados: { entraram: entram, sairam: saem })
        end
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      # Lista fixa (TIPOS): nunca vem de parâmetro.
      def modelo = @tipo[:modelo] == "Ti::PerfilAbertura" ? Ti::PerfilAbertura : Ti::GrupoTecnico
    end
  end
end
