module Transporte
  # Painel de acompanhamento do Transporte (porta de transport-public-tracking-board.tsx): tela para
  # TV, sem login, liberada pela senha da Configuração. Não herda do BaseController: aqui não há usuário.
  class AcompanhamentoController < ApplicationController
    CHAVE = :transporte_painel_liberado_em
    VALIDADE = 12.hours
    ATUALIZA_A_CADA = 30 # segundos; além disso, o quadro atualiza na hora quando algo muda na operação

    skip_before_action :authenticate_user!
    skip_before_action :exigir_troca_de_senha
    layout "publico"

    def show
      @configuracao = Transporte::Configuracao.atual
      return render(:desligado, status: :not_found) unless @configuracao.painel_ligado?
      return render(:senha) unless liberado?

      @quadro = Transporte::Acompanhamento::Quadro.new
    end

    def create
      configuracao = Transporte::Configuracao.atual
      if configuracao.senha_do_painel_confere?(params[:senha])
        session[CHAVE] = Time.current.to_i
        redirect_to transporte_acompanhamento_path, status: :see_other
      else
        @erro = "Senha de acesso inválida."
        render :senha, status: :unprocessable_content
      end
    end

    def destroy
      session.delete(CHAVE)
      redirect_to transporte_acompanhamento_path, status: :see_other
    end

    private

    def liberado? = session[CHAVE].to_i > VALIDADE.ago.to_i
  end
end
