module Equipamentos
  module Itens
    # Excel (.xlsx) da lista de equipamentos, com os filtros da tela (porta de exportar_excel.xlsx.axlsx):
    # cabeçalho com quem gerou e quando, e as peças de cada kit juntas.
    module Planilha
      COLUNAS = [ "Código do kit", "Identificação do kit", "Tipo", "Marca", "Modelo", "Número serial", "Patrimônio", "Outra identificação", "Situação", "Disponibilidade", "Unidade",
                  "Emprestado para", "Contrato/Referência", "Processo", "Garantia (meses)", "Host", "IP", "MAC", "Ativo de rede", "Localização física", "Rack", "Descrição",
                  "Cadastrado em" ].freeze

      module_function

      def gerar(itens, gerado_por:)
        pacote = Axlsx::Package.new
        pacote.workbook.tap do |pasta|
          negrito = pasta.styles.add_style(b: true)
          pasta.add_worksheet(name: "Equipamentos") do |aba|
            aba.add_row [ "Relatório de equipamentos" ], style: negrito
            aba.add_row [ "Gerado por", gerado_por.nome ]
            aba.add_row [ "Gerado em", I18n.l(Time.current, format: "%d/%m/%Y %H:%M") ]
            aba.add_row [ "Total de equipamentos", itens.count ]
            aba.add_row []
            aba.add_row COLUNAS, style: negrito
            itens.find_each(batch_size: 500) { |item| aba.add_row linha(item), types: [ :string ] * COLUNAS.size }
          end
        end
        pacote.to_stream.read
      end

      def linha(item)
        [ item.codigo_kit, item.identificacao_kit, item.tipo_equipamento, item.marca, item.modelo, item.numero_serial, item.numero_patrimonio, item.outra_identificacao, item.nome_do_status,
          item.nome_da_situacao, item.unidade_nome, item.posse_unidade_nome, item.contrato, item.processo, item.garantia, item.host, item.ip, item.mac, item.ativo_de_rede,
          item.localizacao_fisica, item.rack, item.descricao, I18n.l(item.created_at, format: "%d/%m/%Y %H:%M") ].map { |valor| valor.to_s }
      end
    end
  end
end
