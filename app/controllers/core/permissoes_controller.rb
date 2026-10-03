module Core
  # Administração → Usuários → Permissões: editor de acessos por módulo
  # de um usuário (conceder/revogar papéis, bloquear/liberar módulos).
  class PermissoesController < BaseController
    before_action :carregar_usuario
    before_action { pode!("core.permissoes.conceder") }

    def show
      montar_painel
    end

    # Concede um papel.
    def create
      responder Acessos::Conceder.call(user: @usuario, modulo: params[:modulo], papel: params[:papel], concedido_por: current_user),
                "Permissão concedida."
    end

    # Revoga uma concessão.
    def destroy
      concessao = @usuario_concessoes.find(params[:concessao_id])
      responder Acessos::Revogar.call(concessao: concessao, revogado_por: current_user), "Permissão revogada."
    end

    # Bloqueia ou libera o módulo inteiro.
    def update
      liberar = params[:status] == "ativo"
      responder Acessos::AlterarModulo.call(user: @usuario, modulo: params[:modulo], ativo: liberar, alterado_por: current_user),
                (liberar ? "Módulo liberado." : "Módulo bloqueado.")
    end

    private

    def carregar_usuario
      @usuario = ::User.find(params[:usuario_id])
      @usuario_concessoes = Core::Concessao.ativo.where(user: @usuario)
    end

    def responder(resultado, aviso)
      @aviso = aviso if resultado.sucesso?
      @erro = resultado.mensagem_de_erro if resultado.falha?
      montar_painel
      render :show, status: (resultado.sucesso? ? :ok : :unprocessable_content)
    end

    def montar_painel
      concessoes = @usuario_concessoes.reload.order(:papel).group_by(&:modulo)
      acessos = Core::Acesso.where(user: @usuario).pluck(:modulo, :status).to_h
      autorizacao_do_usuario = Core::Autorizacao.new(@usuario)

      @modulos = Core::Catalogo.modulos.map do |modulo|
        concedidas = concessoes.fetch(modulo.chave, [])
        ja_tem = concedidas.select(&:global?).map(&:papel)
        {
          modulo: modulo,
          bloqueado: acessos[modulo.chave] == "inativo",
          entra: autorizacao_do_usuario.acesso?(modulo.chave),
          concessoes: concedidas,
          automaticos: modulo.papeis_automaticos,
          concediveis: modulo.papeis.values.reject(&:automatico?).select do |papel|
            ja_tem.exclude?(papel.chave) && Acessos::Regras.pode_conceder?(current_user, modulo: modulo.chave, papel: papel.chave)
          end
        }
      end
    end
  end
end
