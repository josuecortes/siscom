module Ti
  # Painel de acompanhamento da TI: tela para TV, sem login, liberada pela senha da Configuração da TI,
  # nos moldes do painel do Transporte.
  class AcompanhamentoController < ApplicationController
    include PainelDeTv

    private

    def configuracao_do_painel = @configuracao_do_painel ||= Ti::Configuracao.atual
    def quadro_do_painel = Ti::Acompanhamento::Quadro.new

    def textos_do_painel
      { modulo: "TI", caminho: ti_acompanhamento_path, canal: "ti_operacao", onde_ligar: "O administrador da TI liga definindo uma senha em TI → Administração → Configuração." }
    end
  end
end
