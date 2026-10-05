module Transporte
  module Relatorios
    # Monta o Excel (.xlsx) de um relatório: uma aba com os dados e o resumo, outra com o período.
    module Planilha
      module_function

      def gerar(relatorio)
        pacote = Axlsx::Package.new
        pacote.workbook.tap do |pasta|
          negrito = pasta.styles.add_style(b: true)
          pasta.add_worksheet(name: relatorio.titulo.first(28)) do |aba|
            aba.add_row relatorio.colunas, style: negrito
            relatorio.linhas.each { |linha| aba.add_row linha }
            aba.add_row []
            relatorio.resumo.each { |rotulo, valor| aba.add_row [ rotulo, valor ], style: [ negrito, nil ] }
          end
          pasta.add_worksheet(name: "Período") do |aba|
            aba.add_row [ "Relatório", "Transporte: #{relatorio.titulo}" ]
            aba.add_row [ "Início", I18n.l(relatorio.inicio) ]
            aba.add_row [ "Fim", I18n.l(relatorio.fim) ]
            aba.add_row [ "Gerado em", I18n.l(Time.current, format: "%d/%m/%Y %H:%M") ]
          end
        end
        pacote.to_stream.read
      end
    end
  end
end
