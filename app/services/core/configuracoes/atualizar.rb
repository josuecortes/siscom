module Core
  module Configuracoes
    # Atualiza as configurações do sistema e marca, com auditoria do que mudou.
    class Atualizar
      PERMISSAO = "core.configuracoes.gerenciar".freeze
      PERMITIDOS = (Core::Configuracao::TEXTOS + %i[
        mostrar_nome_marca_web mostrar_nome_marca_celular mostrar_icone_marca_web mostrar_icone_marca_celular
        mostrar_nome_cabecalho_web mostrar_nome_cabecalho_celular mostrar_titulo_login icone_marca favicon
      ]).freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, atualizado_por:, remover: [])
        @atributos = atributos.to_h.symbolize_keys.slice(*PERMITIDOS)
                               .reject { |chave, valor| chave.in?(%i[icone_marca favicon]) && valor.blank? }
        @remover = Array(remover).map(&:to_sym) & %i[icone_marca favicon]
        @atualizado_por = atualizado_por
      end

      def call
        configuracao = Core::Configuracao.atual
        unless Core::Autorizacao.new(@atualizado_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar as configurações.", objeto: configuracao)
        end

        arquivos = @atributos.slice(:icone_marca, :favicon).keys
        return Core::Resultado.falha(configuracao) unless configuracao.update(@atributos)

        @remover.each { |campo| configuracao.public_send(campo).purge if arquivos.exclude?(campo) }
        registrar(configuracao, arquivos)
        Core::Resultado.sucesso(configuracao)
      end

      private

      def registrar(configuracao, arquivos)
        mudancas = configuracao.saved_changes.except("updated_at").transform_values { |de, para| { de: de, para: para } }
        imagens = { trocadas: arquivos, removidas: @remover - arquivos }.reject { |_, lista| lista.empty? }
        return if mudancas.empty? && imagens.empty?

        Core::Auditoria::Registrar.call(evento: "core.configuracao.atualizada", ator: @atualizado_por,
                                        descricao: "Configurações do sistema", dados: { mudancas: mudancas, imagens: imagens }.compact_blank)
      end
    end
  end
end
