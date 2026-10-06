module Equipamentos
  module Envios
    # Texto do termo de responsabilidade do empréstimo ou cautela. É montado quando a pessoa abre para aceitar e
    # fica gravado no envio no momento do aceite: é esse texto que quem recebe a devolução vê depois.
    module Termo
      module_function

      def texto(envio, em: Time.current)
        equipamentos = envio.itens.reject(&:cancelado?).map { |item| "  - #{descricao(item.item)}" }.join("\n")
        <<~TERMO.strip
          TERMO DE RESPONSABILIDADE — #{envio.nome_do_tipo.upcase} DE EQUIPAMENTO (#{envio.codigo})

          Eu, #{envio.responsavel_nome}, lotado(a) em #{envio.destino_nome}, declaro que recebi de #{envio.criada_por_nome}, pela unidade #{envio.origem_nome}, em #{I18n.l(em.to_date)}, a título de #{envio.nome_do_tipo.downcase}, o(s) equipamento(s) abaixo:

          #{equipamentos}

          Comprometo-me a zelar pela guarda e conservação do(s) equipamento(s), a usá-lo(s) somente no serviço e a devolvê-lo(s) à unidade #{envio.origem_nome} até #{I18n.l(envio.previsao_devolucao)}, nas mesmas condições em que o(s) recebi, respondendo por perda ou dano que não decorra do uso normal.

          A devolução é feita pelo sistema e só se conclui quando um responsável da unidade #{envio.origem_nome} confirmar o recebimento.
        TERMO
      end

      def descricao(equipamento)
        ids = { "patrimônio" => equipamento.numero_patrimonio, "serial" => equipamento.numero_serial, "identificação" => equipamento.outra_identificacao }.compact_blank
        "#{equipamento.nome} (#{ids.map { |nome, valor| "#{nome} #{valor}" }.join(', ')})"
      end
    end
  end
end
