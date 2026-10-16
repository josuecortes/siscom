module Ti
  module Campos
    # Cria ou atualiza um campo do formulário de uma solicitação, com auditoria.
    class Salvar
      CAMPOS = %i[rotulo tipo obrigatorio posicao exemplo mascara ajuda opcoes fonte].freeze

      def self.call(...) = new(...).call

      def initialize(campo:, atributos:, salvo_por:)
        @campo = campo
        @atributos = atributos.to_h.symbolize_keys.slice(*CAMPOS)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @campo)
        end

        novo = @campo.new_record?
        # O tipo vem antes: opções e fonte dependem dele.
        @campo.assign_attributes(@atributos.slice(:tipo))
        return Core::Resultado.falha(@campo) unless @campo.update(@atributos.except(:tipo))

        Core::Api.auditar(evento: "ti.campo.#{novo ? 'criado' : 'atualizado'}", alvo: @campo.problema, ator: @salvo_por,
                          dados: { campo: @campo.chave, rotulo: @campo.rotulo, tipo: @campo.tipo })
        Core::Resultado.sucesso(@campo)
      end
    end
  end
end
