module Ti
  # Perfis de abertura (quem abre) e grupos técnicos (quem atende) de uma solicitação.
  # O tipo ("perfis" ou "grupos") vem da rota.
  class VinculosDaSolicitacaoController < BaseController
    TEXTOS = {
      "perfis" => { sobretitulo: "Perfis de abertura", titulo: "Perfis de abertura de %s", legenda: "Quem pode abrir",
                    ajuda: "Usuários desses perfis podem abrir esta solicitação.", aviso: "Perfis de abertura de %s atualizados.",
                    vazio: "Nenhum perfil de abertura ativo. Cadastre em TI → Administração → Perfis de abertura." },
      "grupos" => { sobretitulo: "Grupos técnicos", titulo: "Grupos técnicos de %s", legenda: "Quem atende",
                    ajuda: "Triadores e técnicos desses grupos podem pegar os chamados desta solicitação.", aviso: "Grupos técnicos de %s atualizados.",
                    vazio: "Nenhum grupo técnico ativo. Cadastre em TI → Administração → Grupos técnicos." }
    }.freeze

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action :carregar

    def edit
      @marcados = @tipo == "perfis" ? @solicitacao.perfil_abertura_ids : @solicitacao.grupo_tecnico_ids
    end

    def update
      resultado = Ti::Solicitacoes::DefinirVinculos.call(solicitacao: @solicitacao, tipo: @tipo, ids: params[:ids], definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: format(@textos[:aviso], @solicitacao.nome), voltar_para: ti_solicitacoes_path)
      else
        @erro = resultado.mensagem_de_erro
        @marcados = Array(params[:ids]).map(&:to_i)
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar
      @solicitacao = Ti::Problema.find(params[:solicitacao_id])
      @tipo = params[:tipo].presence_in(TEXTOS.keys) || raise(ActiveRecord::RecordNotFound)
      @textos = TEXTOS.fetch(@tipo)
      @opcoes = (@tipo == "perfis" ? Ti::PerfilAbertura : Ti::GrupoTecnico).ativo.ordenados.to_a
    end
  end
end
