module Ti
  # Membros de um grupo técnico (porta de helpdesk-technical-groups-module.tsx): busca para
  # adicionar e lista com × para tirar. Só entra quem tem permissão na TI (administrador,
  # supervisor, triador ou técnico). Cada mudança vale na hora.
  class MembrosDoGrupoController < BaseController
    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action { @grupo = Ti::GrupoTecnico.find(params[:grupo_tecnico_id]) }

    def edit
      montar_painel
    end

    def create
      alvo = Ti::Grupos.elegiveis.find_by(id: params[:user_id])
      return responder(nil, erro: "Escolha na lista alguém com permissão na TI.") unless alvo

      responder(definir(@grupo.vinculos_de_membro.pluck(:user_id) + [ alvo.id ]), aviso: "#{alvo.nome} entrou no grupo.")
    end

    def destroy
      alvo = @grupo.membros.find(params[:user_id])
      responder(definir(@grupo.vinculos_de_membro.pluck(:user_id) - [ alvo.id ]), aviso: "#{alvo.nome} saiu do grupo.")
    end

    private

    def definir(ids) = Ti::Grupos::DefinirMembros.call(grupo: @grupo, user_ids: ids, definido_por: current_user)

    def responder(resultado, aviso: nil, erro: nil)
      @erro = erro || (resultado.mensagem_de_erro if resultado.falha?)
      @aviso = aviso unless @erro
      montar_painel
      render :edit, status: (@erro ? :unprocessable_content : :ok)
    end

    def montar_painel
      @membros = @grupo.membros.order(:nome, :id).to_a
      @papeis = Core::Api.papeis_concedidos(@membros.map(&:id), modulo: :ti)
    end
  end
end
