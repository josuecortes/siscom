module Ti
  # TI → Acompanhamento: explica o painel de TV dos chamados e abre ele (a senha fica com os administradores da TI).
  class SobreAcompanhamentoController < BaseController
    include SobreOPainelDeTv

    private

    def permissao_do_sobre = "ti.acompanhamento.ver"

    def textos_do_sobre
      { modulo: "TI", modulo_chave: "ti", caminho_do_painel: ti_acompanhamento_path, configuracao: Ti::Configuracao.atual,
        onde_ligar: "TI → Administração → Configuração",
        o_que: "os chamados de TI em aberto, em tempo real",
        colunas: [ [ "Aguardando atendimento", "chamados abertos (ou liberados de novo) que ainda não têm técnico. É aqui que chega o que é novo." ],
                   [ "Em triagem", "chamados sendo triados, com quem está triando." ],
                   [ "Em atendimento", "chamados com técnico, com quem está atendendo." ],
                   [ "Parados", "chamados esperando ajuste do solicitante ou impedidos." ] ] }
    end
  end
end
