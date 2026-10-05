module Transporte
  # Alertas automáticos do Transporte, rodando a cada minuto pelo Solid Queue (config/recurring.yml).
  # Porta de departure_reminder_notification_job.rb e pickup_overdue_notification_job.rb do seed:
  # - lembrete de saída: solicitação aprovada que sai nos próximos N minutos (Configuração), uma vez só,
  #   para o solicitante e a operação;
  # - busca atrasada: aguardando busca além da hora prevista, sem motorista a caminho; repete a cada
  #   N minutos para a operação.
  class AlertasJob < ApplicationJob
    queue_as :default

    def perform
      configuracao = Transporte::Configuracao.atual
      lembrar_saidas(configuracao.lembrete_saida_minutos)
      avisar_buscas_atrasadas(configuracao.aviso_busca_atrasada_minutos)
    end

    private

    def lembrar_saidas(minutos)
      agora = Time.current
      Transporte::Solicitacao.aprovada.where(lembrete_enviado_em: nil, saida_em: agora..(agora + minutos.minutes)).find_each do |solicitacao|
        saida = I18n.l(solicitacao.saida_em, format: "%H:%M")
        Solicitacoes::Avisos.notificar(solicitacao.solicitante, solicitacao, nil, :solicitante, "Seu transporte sai às #{saida}",
                                       "#{solicitacao.codigo}: esteja pronto no horário combinado.")
        Solicitacoes::Avisos.notificar(Solicitacoes::Avisos.operacao.to_a, solicitacao, nil, :operacao, "Saída às #{saida}",
                                       "#{solicitacao.codigo} (#{solicitacao.solicitante_nome}) sai às #{saida} e ainda não tem motorista em serviço.")
        solicitacao.update_column(:lembrete_enviado_em, agora) # rubocop:disable Rails/SkipsModelValidations -- só o carimbo do aviso
      end
    end

    def avisar_buscas_atrasadas(intervalo)
      agora = Time.current
      a_caminho = Transporte::Servico.abertos.select(:solicitacao_id)
      Transporte::Solicitacao.busca.where(busca_prevista_em: ..agora).where.not(id: a_caminho)
                             .where("ultimo_aviso_de_busca_em IS NULL OR ultimo_aviso_de_busca_em <= ?", agora - intervalo.minutes).find_each do |solicitacao|
        Solicitacoes::Avisos.notificar(Solicitacoes::Avisos.operacao.to_a, solicitacao, nil, :operacao, "Busca em atraso",
                                       "#{solicitacao.codigo} (#{solicitacao.solicitante_nome}) espera a busca desde #{I18n.l(solicitacao.busca_prevista_em, format: '%d/%m %H:%M')}.")
        solicitacao.update_column(:ultimo_aviso_de_busca_em, agora) # rubocop:disable Rails/SkipsModelValidations -- só o carimbo do aviso
      end
    end
  end
end
