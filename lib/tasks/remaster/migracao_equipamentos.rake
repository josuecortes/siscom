# Migração dos equipamentos e das movimentações do siscom antigo para o módulo Equipamentos.
# O MESMO script roda em desenvolvimento e em produção. Idempotente: pode rodar de novo (só traz o que falta).
# De-para, decisões e ajustes: docs/refactor-remaster/06-migracao-dos-equipamentos.md.
#
# Ordem em produção (na virada, com as tabelas novas ainda vazias, para os números baterem com os antigos):
#   bin/rails db:migrate
#   bin/rails remaster:migracao:equipamentos
#   bin/rails remaster:migracao:conferir_equipamentos
#   bin/rails remaster:migracao:de_para_equipamentos   # opcional: planilha Excel em tmp/
namespace :remaster do
  namespace :migracao do
    desc "Traz os equipamentos e as movimentações do siscom antigo para o módulo novo (idempotente)."
    task equipamentos: :environment do
      relatorio = Equipamentos::Importacao::DoLegado.call
      puts "Equipamentos: #{relatorio}"
      relatorio.ajustados.each { |linha| puts "  ajustado #{linha}" }
      relatorio.ignorados.each { |linha| puts "  ignorado #{linha}" }
    end

    desc "Confere os equipamentos e as movimentações antigos contra os novos. Sai com erro se algo não bate."
    task conferir_equipamentos: :environment do
      c = ActiveRecord::Base.connection
      falhas = 0
      conferir = lambda do |titulo, antigo, novo|
        ok = antigo == novo
        falhas += 1 unless ok
        puts format("%-66s antigo %6d   novo %6d   %s", titulo, antigo, novo, ok ? "ok" : "DIFERENTE")
      end
      valor = ->(sql) { c.select_value(sql).to_i }
      itens = Equipamentos::Item.where.not(legacy_id: nil)
      envios = Equipamentos::Movimentacao.where.not(legacy_id: nil)
      linhas = Equipamentos::ItemMovimentacao.where.not(legacy_id: nil)
      reais = "movimentacao_equipamentos m WHERE m.unidade_origem_id <> m.unidade_destino_id"
      das_reais = "item_movimentacoes i JOIN movimentacao_equipamentos m ON m.id = i.movimentacao_equipamento_id WHERE m.unidade_origem_id <> m.unidade_destino_id"

      conferir.call("Equipamentos", valor.call("SELECT COUNT(*) FROM equipamentos"), itens.count)
      conferir.call("Números iguais aos antigos (equipamentos)", valor.call("SELECT COUNT(*) FROM equipamentos"), itens.where("id = legacy_id").count)
      Equipamentos::Importacao::DoLegado::STATUS.each do |antigo, novo|
        conferir.call("Situação antiga #{antigo} -> #{novo}", valor.call("SELECT COUNT(*) FROM equipamentos WHERE status = #{antigo}"), itens.where(status: novo).count)
      end
      c.select_rows("SELECT tipo_equipamento, COUNT(*) FROM equipamentos GROUP BY 1 ORDER BY 1").each do |tipo, total|
        conferir.call("Tipo #{tipo}", total, itens.where(tipo_equipamento: tipo).count)
      end
      c.select_rows("SELECT e.unidade_id, COUNT(*) FROM equipamentos e GROUP BY 1 ORDER BY 2 DESC, 1").each do |unidade_id, total|
        unidade = Rh::Api.unidade_do_legado(unidade_id)
        conferir.call("Unidade #{unidade&.sigla_e_nome || "antiga #{unidade_id} (sem unidade nova)"}".truncate(64), total, unidade ? itens.where(rh_unidade_id: unidade.id).count : 0)
      end
      conferir.call("Kits (códigos de kit diferentes)", valor.call("SELECT COUNT(DISTINCT UPPER(codigo_kit)) FROM equipamentos WHERE COALESCE(codigo_kit, '') <> ''"),
                    itens.where.not(codigo_kit: nil).distinct.count(:codigo_kit))
      conferir.call("Com serial / com patrimônio (somados)", valor.call("SELECT COUNT(NULLIF(numero_serial, '')) + COUNT(NULLIF(numero_patrimonio, '')) FROM equipamentos"),
                    itens.where.not(numero_serial: nil).count + itens.where.not(numero_patrimonio: nil).count)
      conferir.call("Linhas de histórico antigas presentes", valor.call("SELECT COALESCE(SUM(jsonb_array_length(historico_movimentacoes)), 0) FROM equipamentos"),
                    Equipamentos::Evento.where(item_id: itens.select(:id), tipo: %w[cadastrado movimentacao_recebida situacao_alterada legado]).where("nota IS NULL OR nota NOT LIKE 'Trazido do siscom antigo:%'").count)

      conferir.call("Movimentações (sem as iniciais)", valor.call("SELECT COUNT(*) FROM #{reais}"), envios.count)
      conferir.call("Números iguais aos antigos (movimentações)", valor.call("SELECT COUNT(*) FROM #{reais}"), envios.where("id = legacy_id").count)
      %w[em_andamento concluida cancelada].each do |status|
        conferir.call("Movimentações #{status}", valor.call("SELECT COUNT(*) FROM #{reais} AND m.status = '#{status}'"), envios.where(status: status).count)
      end
      conferir.call("Equipamentos nas movimentações", valor.call("SELECT COUNT(*) FROM #{das_reais}"), linhas.count)
      Equipamentos::Importacao::DoLegado::DA_LINHA.each do |antigo, novo|
        conferir.call("Nas movimentações: #{antigo} -> #{novo}", valor.call("SELECT COUNT(*) FROM #{das_reais} AND i.status = '#{antigo}'"), linhas.where(status: novo).count)
      end
      conferir.call("Equipamentos em movimentação = pendentes de recebimento", linhas.pendente.count, itens.em_movimentacao.count)
      conferir.call("Nenhum equipamento antigo emprestado (o empréstimo é novo)", 0, itens.emprestado.count)
      abort "#{falhas} conferência(s) com diferença." if falhas.positive?
      puts "Tudo confere."
    end

    desc "Gera o de-para (planilha em tmp/de-para-equipamentos.xlsx): cada equipamento e movimentação antigos e como ficaram no módulo novo."
    task de_para_equipamentos: :environment do
      c = ActiveRecord::Base.connection
      data = ->(momento) { momento && I18n.l(momento, format: "%d/%m/%Y %H:%M") }
      pacote = Axlsx::Package.new
      titulo = pacote.workbook.styles.add_style(b: true)
      unidades = c.select_rows("SELECT id, COALESCE(NULLIF(sigla, '') || ' - ', '') || nome FROM unidades").to_h
      status_antigo = { 0 => "ativo", 1 => "inativo", 2 => "em_manutencao", 3 => "descartado" }

      novos = Equipamentos::Item.where.not(legacy_id: nil).index_by(&:legacy_id)
      eventos = Equipamentos::Evento.where(item_id: novos.values.map(&:id)).group(:item_id).count
      pacote.workbook.add_worksheet(name: "Equipamentos") do |planilha|
        planilha.add_row [ "Nº antigo", "Tipo", "Patrimônio antigo", "Serial antigo", "Unidade antiga", "Situação antiga", "Nº novo", "Patrimônio", "Serial", "Unidade nova", "Situação nova",
                           "Onde está agora", "Código do kit", "Linhas no histórico", "Linhas no histórico antigo" ], style: titulo
        c.select_rows("SELECT id, tipo_equipamento, numero_patrimonio, numero_serial, unidade_id, status, jsonb_array_length(historico_movimentacoes) FROM equipamentos ORDER BY id")
         .each do |id, tipo, patrimonio, serial, unidade_id, status, historico|
          n = novos[id]
          planilha.add_row [ id, tipo, patrimonio, serial, unidades[unidade_id], status_antigo[status], n&.id || "NÃO MIGRADO", n&.numero_patrimonio, n&.numero_serial, n&.unidade_nome, n&.nome_do_status,
                             n&.nome_da_situacao, n&.codigo_kit, (n && eventos.fetch(n.id, 0)), historico ], types: [ nil, nil, :string, :string, nil, nil, nil, :string, :string ]
        end
      end

      envios = Equipamentos::Movimentacao.where.not(legacy_id: nil).includes(:itens).index_by(&:legacy_id)
      pacote.workbook.add_worksheet(name: "Movimentações") do |planilha|
        planilha.add_row [ "Nº antigo", "Situação antiga", "Origem antiga", "Destino antigo", "Equipamentos (antigo)", "Código novo", "Situação nova", "Origem", "Destino", "Quem recebe",
                           "Enviado por", "Enviado em", "Aguardando recebimento", "Recebidos", "Cancelados" ], style: titulo
        c.select_rows("SELECT m.id, m.status, m.unidade_origem_id, m.unidade_destino_id, (SELECT COUNT(*) FROM item_movimentacoes i WHERE i.movimentacao_equipamento_id = m.id) " \
                      "FROM movimentacao_equipamentos m WHERE m.unidade_origem_id <> m.unidade_destino_id ORDER BY m.id").each do |id, status, origem, destino, total|
          n = envios[id]
          por_status = n ? n.itens.group_by(&:status).transform_values(&:size) : {}
          planilha.add_row [ id, status, unidades[origem], unidades[destino], total, n&.codigo || "NÃO MIGRADA", n&.nome_do_status, n&.origem_nome, n&.destino_nome, n&.responsavel_nome,
                             n&.criada_por_nome, data.call(n&.created_at), por_status.fetch("pendente", 0), por_status.fetch("recebido", 0), por_status.fetch("cancelado", 0) ]
        end
      end

      arquivo = Rails.root.join("tmp/de-para-equipamentos.xlsx")
      pacote.serialize(arquivo.to_s)
      iniciais = c.select_value("SELECT COUNT(*) FROM movimentacao_equipamentos WHERE unidade_origem_id = unidade_destino_id")
      puts "Gerado: #{arquivo} (abas Equipamentos e Movimentações). Fora da planilha: #{iniciais} movimentações iniciais (origem = destino), que não são migradas."
    end
  end

  namespace :dev do
    desc "Apaga TODOS os equipamentos, movimentações e históricos do módulo novo, para a migração começar do zero. Só desenvolvimento."
    task limpar_equipamentos: :environment do
      abort "Só roda em desenvolvimento." unless Rails.env.development?

      ActiveRecord::Base.transaction do
        notificacoes = Core::Notificacao.where(alvo_tipo: "Equipamentos::Movimentacao").delete_all
        linhas = Equipamentos::ItemMovimentacao.delete_all
        envios = Equipamentos::Movimentacao.delete_all
        eventos = Equipamentos::Evento.delete_all
        itens = Equipamentos::Item.delete_all
        puts "Apagados: #{itens} equipamentos, #{envios} envios (#{linhas} equipamentos neles), #{eventos} linhas de histórico, #{notificacoes} notificações."
      end
    end
  end
end
