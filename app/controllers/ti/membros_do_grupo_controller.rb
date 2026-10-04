module Ti
  # Membros de um grupo técnico (porta de helpdesk-technical-groups-module.tsx).
  class MembrosDoGrupoController < BaseController
    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action do
      @grupo = Ti::GrupoTecnico.find(params[:grupo_tecnico_id])
      @elegiveis = Ti::Grupos.elegiveis.to_a
      @papeis = Core::Api.papeis_concedidos(@elegiveis.map(&:id), modulo: :ti)
    end

    def edit
      @marcados = @grupo.vinculos_de_membro.pluck(:user_id)
    end

    def update
      resultado = Ti::Grupos::DefinirMembros.call(grupo: @grupo, user_ids: params[:user_ids], definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Membros de #{@grupo.nome} atualizados.", voltar_para: ti_grupos_tecnicos_path)
      else
        @erro = resultado.mensagem_de_erro
        @marcados = Array(params[:user_ids]).map(&:to_i)
        render :edit, status: :unprocessable_content
      end
    end
  end
end
