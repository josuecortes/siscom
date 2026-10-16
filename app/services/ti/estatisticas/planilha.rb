module Ti
  module Estatisticas
    # Monta o Excel (.xlsx) das estatísticas: uma aba de resumo e uma por seção.
    module Planilha
      module_function

      def gerar(resultado)
        pacote = Axlsx::Package.new
        pacote.workbook.tap do |pasta|
          negrito = pasta.styles.add_style(b: true)
          pasta.add_worksheet(name: "Resumo") do |aba|
            aba.add_row [ "Relatórios da TI" ], style: negrito
            aba.add_row [ "Período (data de abertura)", "#{I18n.l(resultado.inicio)} a #{I18n.l(resultado.fim)}" ]
            aba.add_row [ "Categoria", resultado.categoria&.nome || "Todas" ]
            aba.add_row [ "Técnico", resultado.tecnico&.nome || "Todos" ]
            aba.add_row [ "Gerado em", I18n.l(Time.current, format: "%d/%m/%Y %H:%M") ]
            aba.add_row []
            resultado.resumo.each { |rotulo, valor| aba.add_row [ rotulo, valor ], style: [ negrito, nil ] }
          end
          resultado.secoes.each do |secao|
            pasta.add_worksheet(name: secao.titulo.first(28)) do |aba|
              aba.add_row secao.colunas, style: negrito
              secao.linhas.each { |linha| aba.add_row linha }
            end
          end
        end
        pacote.to_stream.read
      end
    end
  end
end
