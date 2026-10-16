module Ti
  # TI → Administração → Configuração: a senha do painel de acompanhamento.
  class ConfiguracoesController < BaseController
    before_action { pode!(Ti::Configuracoes::Atualizar::PERMISSAO) }

    def show
      @configuracao = Ti::Configuracao.atual
    end

    def update
      resultado = Ti::Configuracoes::Atualizar.call(atributos: params.expect(configuracao: [ :senha_do_painel ]), atualizado_por: current_user)
      @configuracao = resultado.objeto

      if resultado.sucesso?
        redirect_to ti_configuracoes_path, notice: "Configurações da TI salvas.", status: :see_other
      else
        render :show, status: :unprocessable_content
      end
    end
  end
end
