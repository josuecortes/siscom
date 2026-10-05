# Migração dos chamados de TI e das requisições de transporte do siscom antigo para os módulos novos.
# O MESMO script roda em desenvolvimento e em produção. Idempotente: pode rodar de novo (só traz o que falta).
# De-para, decisões e mudanças de banco: docs/refactor-remaster/05-migracao-dos-chamados-antigos.md.
#
# Ordem em produção (na virada, com as tabelas novas ainda vazias, para os números baterem com os antigos):
#   bin/rails db:migrate
#   bin/rails remaster:ti:catalogo_inicial            # se ainda não rodou (os chamados precisam das solicitações)
#   bin/rails remaster:migracao:chamados_de_ti
#   bin/rails remaster:migracao:solicitacoes_de_transporte
#   bin/rails remaster:migracao:conferir
#   bin/rails remaster:migracao:de_para               # opcional: planilha Excel em tmp/
namespace :remaster do
  namespace :migracao do
    desc "Traz os chamados de TI do siscom antigo para o módulo novo (idempotente)."
    task chamados_de_ti: :environment do
      relatorio = Ti::Importacao::Chamados.call
      puts "TI: #{relatorio}"
      relatorio.ignorados.each { |linha| puts "  ignorado #{linha}" }
    end

    desc "Traz as requisições de transporte do siscom antigo para o módulo novo (idempotente)."
    task solicitacoes_de_transporte: :environment do
      relatorio = Transporte::Importacao::Solicitacoes.call
      puts "Transporte: #{relatorio}"
      relatorio.ignoradas.each { |linha| puts "  ignorada #{linha}" }
    end

    desc "Confere as contagens do antigo contra o novo, por situação. Sai com erro se algo não bate."
    task conferir: :environment do
      c = ActiveRecord::Base.connection
      falhas = 0
      conferir = lambda do |titulo, antigo, novo|
        ok = antigo == novo
        falhas += 1 unless ok
        puts format("%-58s antigo %6d   novo %6d   %s", titulo, antigo, novo, ok ? "ok" : "DIFERENTE")
      end
      conferir.call("TI: chamados", c.select_value("SELECT COUNT(*) FROM requisicao_tis"), Ti::Chamado.where.not(legacy_id: nil).count)
      Ti::Importacao::Chamados::STATUS.each do |antigo, novo|
        conferir.call("TI: situação antiga #{antigo} -> #{novo}", c.select_value("SELECT COUNT(*) FROM requisicao_tis WHERE status = #{antigo}"),
                      Ti::Chamado.where.not(legacy_id: nil).where(status: novo).count)
      end
      conferir.call("TI: avaliações", c.select_value("SELECT COUNT(*) FROM requisicao_tis WHERE avaliacao IS NOT NULL"), Ti::Chamado.where.not(legacy_id: nil).where.not(avaliacao: nil).count)
      conferir.call("TI: chamados com mensagens", c.select_value("SELECT COUNT(DISTINCT requisicao_ti_id) FROM mensagens WHERE texto <> ''"),
                    c.select_value("SELECT COUNT(*) FROM core_conversas k JOIN ti_chamados t ON t.id = k.alvo_id AND k.alvo_tipo = 'Ti::Chamado' WHERE t.legacy_id IS NOT NULL"))
      conferir.call("Transporte: requisições", c.select_value("SELECT COUNT(*) FROM requisicao_transportes"), Transporte::Solicitacao.where.not(legacy_id: nil).count)
      conferir.call("Transporte: finalizadas -> concluídas", c.select_value("SELECT COUNT(*) FROM requisicao_transportes WHERE status = 6"),
                    Transporte::Solicitacao.where.not(legacy_id: nil).concluida.count)
      # Requisição antiga sem passageiro (ou sem destino) ganha um na migração: o formato novo sempre tem ao menos um.
      %w[passageiros destinos].each do |filho|
        sem = c.select_value("SELECT COUNT(*) FROM requisicao_transportes r WHERE NOT EXISTS (SELECT 1 FROM #{filho} f WHERE f.requisicao_transporte_id = r.id)")
        conferir.call("Transporte: #{filho} (antigos + #{sem} acrescentados)", c.select_value("SELECT COUNT(*) FROM #{filho}") + sem,
                      c.select_value("SELECT COUNT(*) FROM transporte_#{filho} f JOIN transporte_solicitacoes s ON s.id = f.solicitacao_id WHERE s.legacy_id IS NOT NULL"))
      end
      conferir.call("Transporte: nenhuma migrada parada como solicitada/aprovada há mais de um mês", 0,
                    Transporte::Solicitacao.where.not(legacy_id: nil).where(status: %w[solicitada aprovada], saida_em: ..1.month.ago).count)
      conferir.call("Números iguais aos antigos (TI)", c.select_value("SELECT COUNT(*) FROM requisicao_tis"), Ti::Chamado.where("id = legacy_id").count)
      conferir.call("Números iguais aos antigos (Transporte)", c.select_value("SELECT COUNT(*) FROM requisicao_transportes"), Transporte::Solicitacao.where("id = legacy_id").count)
      abort "#{falhas} conferência(s) com diferença." if falhas.positive?
      puts "Tudo confere."
    end

    desc "Gera o de-para (planilha em tmp/de-para-chamados-antigos.xlsx): cada chamado e requisição antigos e como ficaram no formato novo."
    task de_para: :environment do
      c = ActiveRecord::Base.connection
      data = ->(momento) { momento && I18n.l(momento, format: "%d/%m/%Y %H:%M") }
      pacote = Axlsx::Package.new
      titulo = pacote.workbook.styles.add_style(b: true)

      ti_antigo = { 1 => "Solicitada", 2 => "Em atendimento", 3 => "Concluída", 4 => "Cancelada", 5 => "Finalizada" }
      mensagens = c.select_rows("SELECT k.alvo_id, COUNT(m.id) FROM core_conversas k JOIN core_mensagens m ON m.conversa_id = k.id WHERE k.alvo_tipo = 'Ti::Chamado' GROUP BY 1").to_h
      pacote.workbook.add_worksheet(name: "TI") do |planilha|
        planilha.add_row [ "Nº antigo", "Situação antiga", "Aberto em", "Código novo", "Situação nova", "Solicitação", "Solicitante", "Unidade", "Técnico", "Dados informados",
                           "Linhas no histórico", "Mensagens" ], style: titulo
        c.select_rows("SELECT id, status FROM requisicao_tis ORDER BY id").each_slice(1000) do |lote|
          novos = Ti::Chamado.where(legacy_id: lote.map(&:first)).includes(:problema, :responsavel).index_by(&:legacy_id)
          valores = Ti::ValorCampo.where(chamado_id: novos.values.map(&:id)).group(:chamado_id).count
          eventos = Ti::EventoChamado.where(chamado_id: novos.values.map(&:id)).group(:chamado_id).count
          lote.each do |id, status|
            n = novos[id]
            planilha.add_row [ id, ti_antigo[status], data.call(n&.aberto_em), n&.codigo || "NÃO MIGRADO", n&.nome_do_status, n&.problema&.nome, n&.solicitante_nome, n&.unidade_nome,
                               n&.responsavel&.nome, (n && valores.fetch(n.id, 0)), (n && eventos.fetch(n.id, 0)), (n && mensagens.fetch(n.id, 0)) ]
          end
        end
      end

      tipos = { 1 => "Urgente", 2 => "Normal", 3 => "Viagem" }
      novas = Transporte::Solicitacao.where.not(legacy_id: nil).includes(:passageiros, :destinos).index_by(&:legacy_id)
      pacote.workbook.add_worksheet(name: "Transporte") do |planilha|
        planilha.add_row [ "Nº antigo", "Situação antiga", "Tipo antigo", "Saída", "Código novo", "Situação nova", "Tipo novo", "Fora do prazo", "Solicitante", "Unidade", "Passageiros",
                           "Destinos", "Motivo do cancelamento" ], style: titulo
        c.select_rows("SELECT id, status, tipo FROM requisicao_transportes ORDER BY id").each do |id, status, tipo|
          n = novas[id]
          planilha.add_row [ id, Transporte::Importacao::Solicitacoes::NOME_DO_STATUS_ANTIGO[status], tipos[tipo], data.call(n&.saida_em), n&.codigo || "NÃO MIGRADA", n&.nome_do_status,
                             n&.nome_do_tipo, (n && (n.fora_do_padrao? ? "sim" : "não")), n&.solicitante_nome, n&.unidade_nome, n&.passageiros&.size, n&.destinos&.size, n&.motivo_cancelamento ]
        end
      end

      arquivo = Rails.root.join("tmp/de-para-chamados-antigos.xlsx")
      pacote.serialize(arquivo.to_s)
      puts "Gerado: #{arquivo} (abas TI e Transporte)"
    end
  end

  namespace :dev do
    desc "Apaga TODOS os chamados de TI e solicitações de transporte do módulo novo (testes), para a migração começar do zero. Só desenvolvimento."
    task limpar_chamados_e_solicitacoes: :environment do
      abort "Só roda em desenvolvimento." unless Rails.env.development?

      ActiveRecord::Base.transaction do
        tipos = %w[Ti::Chamado Transporte::Solicitacao]
        conversas = Core::Conversa.where(alvo_tipo: tipos).destroy_all.size
        notificacoes = Core::Notificacao.where(alvo_tipo: tipos).delete_all
        chamados = Ti::Chamado.destroy_all.size
        solicitacoes = Transporte::Solicitacao.destroy_all.size
        legado = Ti::CampoProblema.where(ajuda: Ti::Importacao::Chamados::AJUDA_DO_CAMPO_ANTIGO).destroy_all.size
        puts "Apagados: #{chamados} chamados de TI, #{solicitacoes} solicitações de transporte, #{conversas} conversas, #{notificacoes} notificações, #{legado} campos do legado."
      end
    end
  end
end
