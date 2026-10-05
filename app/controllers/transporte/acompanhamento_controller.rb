module Transporte
  # Painel de acompanhamento do Transporte (porta de transport-public-tracking-board.tsx): tela para
  # TV, sem login, liberada pela senha da Configuração.
  class AcompanhamentoController < ApplicationController
    include PainelDeTv

    private

    def configuracao_do_painel = @configuracao_do_painel ||= Transporte::Configuracao.atual
    def quadro_do_painel = Transporte::Acompanhamento::Quadro.new

    def textos_do_painel
      { modulo: "Transporte", caminho: transporte_acompanhamento_path, canal: "transporte_operacao", onde_ligar: "O administrador do Transporte liga definindo uma senha em Transporte → Configuração." }
    end
  end
end
