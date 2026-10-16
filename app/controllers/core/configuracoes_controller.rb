module Core
  # Administração → Configurações (porta de core-settings-module.tsx): marca,
  # cabeçalho, login, ícone e favicon.
  class ConfiguracoesController < BaseController
    before_action { pode!("core.configuracoes.gerenciar") }

    def show
      @configuracao = Core::Configuracao.atual
    end

    def update
      atributos = params.expect(configuracao: Configuracoes::Atualizar::PERMITIDOS)
      remover = %i[icone_marca favicon].select { |campo| params.dig(:remover, campo) == "1" }
      resultado = Configuracoes::Atualizar.call(atributos: atributos, remover: remover, atualizado_por: current_user)
      @configuracao = resultado.objeto

      if resultado.sucesso?
        redirect_to core_configuracoes_path, notice: "Configurações salvas.", status: :see_other
      else
        render :show, status: :unprocessable_content
      end
    end
  end
end
