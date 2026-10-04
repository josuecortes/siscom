module Ti
  # Perfis de abertura de um usuário: quais solicitações ele pode abrir.
  class PerfisDoUsuarioController < BaseController
    before_action { pode!(Ti::Perfis::DefinirDoUsuario::PERMISSAO) }
    before_action do
      @usuario = ::User.ativos.find(params[:permissao_id])
      @perfis = Ti::PerfilAbertura.ativo.ordenados.to_a
    end

    def edit
      @marcados = Ti::PerfilUsuario.where(user: @usuario).pluck(:perfil_abertura_id)
    end

    def update
      resultado = Ti::Perfis::DefinirDoUsuario.call(user: @usuario, perfil_ids: params[:perfil_ids], definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Perfis de abertura de #{@usuario.nome} atualizados.", voltar_para: ti_permissoes_path)
      else
        @erro = resultado.mensagem_de_erro
        @marcados = Array(params[:perfil_ids]).map(&:to_i)
        render :edit, status: :unprocessable_content
      end
    end
  end
end
