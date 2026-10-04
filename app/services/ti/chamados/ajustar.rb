module Ti
  module Chamados
    # O solicitante corrige as respostas do formulário: enquanto o chamado está aberto, ou quando a
    # TI pediu ajuste (aí o chamado volta para a operação, como em Responder). A solicitação não muda.
    #
    # Em falha, `objeto` são as Respostas (com os erros e o que foi digitado).
    class Ajustar
      def self.call(...) = new(...).call

      # O que já foi respondido, no formato que o formulário espera ({ chave do campo => valor }).
      def self.entradas_atuais(chamado)
        chamado.valores.includes(:campo_problema).to_h do |valor|
          atual = case valor.tipo
          when "selecao_multipla" then valor.valor_json["opcoes"]
          when "sim_nao" then valor.valor_texto == "Sim" ? "sim" : "nao"
          when "busca", "busca_multipla" then valor.valor_json["valor"]
          else valor.valor_texto
          end
          [ valor.campo_problema.chave, atual ]
        end
      end

      def initialize(chamado:, user:, respostas:)
        @chamado = chamado
        @user = user
        @entradas = respostas
      end

      def call
        unless @chamado.solicitante_id == @user.id && @chamado.editavel_pelo_solicitante?
          return Core::Resultado.falha("Este chamado não pode mais ser editado.", objeto: nil)
        end

        com_anexo = @chamado.valores.joins(:arquivos_attachments).distinct.pluck(:campo_problema_id)
        respostas = Respostas.new(@chamado.problema, @entradas, anexos_mantidos: com_anexo)
        return Core::Resultado.falha(respostas.erros.values, objeto: respostas) unless respostas.validas?

        de = @chamado.status
        devolvido = @chamado.aguardando_solicitante?
        Ti::Chamado.transaction do
          gravar(respostas.valores)
          @chamado.update!(status: (@chamado.responsavel_id ? "em_atendimento" : (@chamado.triador_id ? "em_triagem" : "aberto"))) if devolvido
          @chamado.eventos.create!(tipo: "respondido", de_status: de, para_status: @chamado.status, ator: @user, ator_nome: @user.nome, ocorrido_em: Time.current,
                                   nota: (devolvido ? "Solicitante ajustou os dados do chamado e reenviou para a TI." : "Solicitante editou os dados do chamado."))
          Core::Api.auditar(evento: "ti.chamado.ajustado", alvo: @chamado, ator: @user, dados: { codigo: @chamado.codigo })
        end
        devolvido ? Avisos.depois_de(@chamado, acao: "responder", de: de, ator: @user) : Avisos.atualizar_telas(@chamado)
        Core::Resultado.sucesso(@chamado)
      end

      private

      def gravar(valores)
        mantidos = valores.map { |valor| valor[:campo].id }
        @chamado.valores.where.not(campo_problema_id: mantidos).destroy_all
        valores.each do |valor|
          next if valor[:manter]

          registro = @chamado.valores.find_or_initialize_by(campo_problema: valor[:campo])
          registro.update!(rotulo: valor[:campo].rotulo, tipo: valor[:campo].tipo, valor_texto: valor[:texto], valor_json: valor[:json] || {})
          next if valor[:arquivos].blank?

          registro.arquivos.purge
          registro.arquivos.attach(valor[:arquivos])
        end
      end
    end
  end
end
