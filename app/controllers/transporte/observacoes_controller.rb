module Transporte
  # Observações de uma solicitação (operação em qualquer uma; motorista nas que atendeu).
  class ObservacoesController < BaseController
    before_action do
      @solicitacao = Transporte::Solicitacao.find(params[:solicitacao_id])
      @papel = Transporte::Solicitacoes::Observar.papel_de(@solicitacao, current_user)
      raise Core::AcessoNegado unless @papel

      @volta = transporte_operacao_index_path
    end

    def new
    end

    def create
      resultado = Transporte::Solicitacoes::Observar.call(solicitacao: @solicitacao, ator: current_user, corpo: params[:corpo], anexos: params[:anexos])

      if resultado.sucesso?
        concluir_painel(aviso: "Observação registrada.", voltar_para: @volta)
      else
        @erro = resultado.mensagem_de_erro
        render :new, status: :unprocessable_content
      end
    end
  end
end
