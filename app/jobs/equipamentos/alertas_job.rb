module Equipamentos
  # Alerta de devolução atrasada, uma vez por dia pelo Solid Queue (config/recurring.yml): empréstimo ou cautela
  # aceito, ainda em aberto, com a data prevista vencida. Avisa uma vez só quem está com o equipamento, quem
  # emprestou e os gestores de equipamentos da unidade de origem. Na lista, o atraso continua em vermelho.
  class AlertasJob < ApplicationJob
    queue_as :default

    def perform(hoje = Date.current)
      gestores = Core::Api.ids_dos_usuarios_com_papel(modulo: "equipamentos", papeis: %w[gestor]).pluck(:user_id)
      Equipamentos::Movimentacao.emprestimos.em_andamento.where.not(aceita_em: nil).where(atraso_avisado_em: nil, previsao_devolucao: ...hoje).find_each do |envio|
        prazo = I18n.l(envio.previsao_devolucao)
        Envios::Avisos.notificar(envio.responsavel, envio, nil, "atrasado", "Devolução de equipamento atrasada",
                                 "#{envio.codigo}: a devolução para #{envio.origem_nome} estava prevista para #{prazo}. Devolva em Meus equipamentos.")
        da_origem = ::User.ativos.where(id: gestores & Rh::Api.ids_dos_usuarios_da_unidade(envio.origem_rh_unidade_id)).to_a
        Envios::Avisos.notificar(([ envio.criada_por ] + da_origem) - [ envio.responsavel ], envio, nil, "atrasado", "#{envio.nome_do_tipo} com a devolução atrasada",
                                 "#{envio.codigo}: #{envio.responsavel_nome} (#{envio.destino_nome}) devia ter devolvido em #{prazo}.",
                                 url: Rails.application.routes.url_helpers.equipamentos_emprestimos_path(atrasados: 1))
        envio.update_column(:atraso_avisado_em, Time.current) # rubocop:disable Rails/SkipsModelValidations -- só o carimbo do aviso
      end
    end
  end
end
