module Transporte
  # Transporte → Configuração (porta de transport-settings-module.tsx): janelas de antecedência,
  # faixas de horas por modo de serviço e alertas.
  class ConfiguracoesController < BaseController
    before_action { pode!(Transporte::Configuracoes::Atualizar::PERMISSAO) }

    def show
      @configuracao = Transporte::Configuracao.atual
    end

    def update
      resultado = Transporte::Configuracoes::Atualizar.call(atributos: params.expect(configuracao: Transporte::Configuracao::CAMPOS),
                                                           atualizado_por: current_user)
      @configuracao = resultado.objeto

      if resultado.sucesso?
        redirect_to transporte_configuracoes_path, notice: "Configurações do Transporte salvas.", status: :see_other
      else
        render :show, status: :unprocessable_content
      end
    end
  end
end
