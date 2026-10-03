module Core
  module FontesReferencia
    # Cria ou atualiza uma fonte de referência (com auditoria). A chave é gerada
    # do nome na criação; fonte gerenciada pelo sistema só muda nome e descrição.
    class Salvar
      PERMISSAO = "core.fontes_referencia.gerenciar".freeze
      PERMITIDOS = %i[nome descricao entidade_completa campo_rotulo campo_valor campo_subtitulo campos_busca tipos_de_campo].freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, salvo_por:, fonte: nil)
        @fonte = fonte || Core::FonteReferencia.new
        @atributos = atributos.to_h.symbolize_keys.slice(*PERMITIDOS)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode gerenciar fontes de referência.", objeto: @fonte)
        end

        nova = @fonte.new_record?
        aplicar_entidade(@atributos.delete(:entidade_completa))
        @fonte.assign_attributes(@atributos)
        @fonte.chave = @fonte.nome if nova
        return Core::Resultado.falha(@fonte) unless @fonte.save

        registrar(nova)
        Core::Resultado.sucesso(@fonte)
      end

      private

      # "core:usuarios" => modulo e entidade
      def aplicar_entidade(valor)
        return if valor.blank?

        @fonte.modulo, @fonte.entidade = valor.to_s.split(":", 2)
      end

      def registrar(nova)
        mudancas = @fonte.saved_changes.except("created_at", "updated_at", "id")
        return if mudancas.empty?

        Core::Auditoria::Registrar.call(
          evento: "core.fonte_referencia.#{nova ? 'criada' : 'atualizada'}", alvo: @fonte, ator: @salvo_por,
          dados: (nova ? { chave: @fonte.chave } : { mudancas: mudancas.transform_values { |de, para| { de: de, para: para } } })
        )
      end
    end
  end
end
