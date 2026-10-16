module Transporte
  # Transporte → Acompanhamento: explica o painel de TV das solicitações e abre ele (a senha fica com os
  # administradores do Transporte).
  class SobreAcompanhamentoController < BaseController
    include SobreOPainelDeTv

    private

    def permissao_do_sobre = "transporte.acompanhamento.ver"

    def textos_do_sobre
      { modulo: "Transporte", modulo_chave: "transporte", caminho_do_painel: transporte_acompanhamento_path, configuracao: Transporte::Configuracao.atual,
        onde_ligar: "Transporte → Administração → Configuração",
        o_que: "as solicitações de transporte do dia, em tempo real",
        colunas: [ [ "Aguardando aprovação", "solicitações novas que ainda não foram aprovadas. É aqui que chega o que é novo." ],
                   [ "Saídas aprovadas", "saídas programadas, pela hora." ],
                   [ "Em andamento", "veículos em serviço, com o motorista." ],
                   [ "Aguardando busca", "quem foi deixado e espera o veículo voltar para buscar." ] ] }
    end
  end
end
