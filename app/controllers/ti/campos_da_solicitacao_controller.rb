module Ti
  # Campos do formulário de uma solicitação (porta de helpdesk-solicitation-fields-module.tsx).
  class CamposDaSolicitacaoController < BaseController
    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action { @solicitacao = Ti::Problema.find(params[:solicitacao_id]) }
    before_action(only: %i[edit update ativar desativar]) { @campo = @solicitacao.campos.find(params[:id]) }
    before_action(only: %i[new create edit update]) { @fontes = Core::Api.fontes_de_referencia.map { |fonte| [ fonte.nome, fonte.chave ] } }

    def index
      @campos = @solicitacao.campos.ordenados
    end

    def new
      @campo = @solicitacao.campos.new
    end

    def create
      salvar(@solicitacao.campos.new, :new, "Campo criado com sucesso.")
    end

    def edit
    end

    def update
      salvar(@campo, :edit, "Campo atualizado com sucesso.")
    end

    def ativar = alterar_status(true, "Campo ativado com sucesso.")
    def desativar = alterar_status(false, "Campo desativado com sucesso.")

    private

    def salvar(campo, tela, aviso)
      resultado = Ti::Campos::Salvar.call(campo: campo, atributos: params.expect(campo: Ti::Campos::Salvar::CAMPOS), salvo_por: current_user)
      @campo = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: ti_solicitacao_campos_path(@solicitacao))
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo, aviso)
      resultado = Ti::Catalogo::AlterarStatus.call(registro: @campo, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to ti_solicitacao_campos_path(@solicitacao), status: :see_other, **opcoes
    end
  end
end
