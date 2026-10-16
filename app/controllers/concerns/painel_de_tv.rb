# Painel de acompanhamento para TV: sem login, liberado pela senha da Configuração do módulo.
# O controller que inclui define:
#   configuracao_do_painel  -> registro com SenhaDoPainel
#   quadro_do_painel        -> objeto com `agora`, `colunas` e `contagem` (ver PainelTv)
#   textos_do_painel        -> { modulo:, caminho:, canal:, onde_ligar: }
# Não herda do BaseController do módulo: aqui não há usuário.
module PainelDeTv
  extend ActiveSupport::Concern

  VALIDADE = 12.hours
  # Segundos entre atualizações quando tudo cabe na tela; com colunas compridas o painel espera a rolagem
  # chegar ao fim (painel_tv_controller.js). Além disso, o quadro atualiza na hora quando algo muda na operação.
  ATUALIZA_A_CADA = 30

  included do
    skip_before_action :authenticate_user!
    skip_before_action :exigir_troca_de_senha
    layout "publico"
  end

  def show
    @textos = textos_do_painel
    return render("compartilhado/painel_tv/desligado", status: :not_found) unless configuracao_do_painel.painel_ligado?
    return render("compartilhado/painel_tv/senha") unless liberado?

    @quadro = quadro_do_painel
    render "compartilhado/painel_tv/quadro"
  end

  def create
    @textos = textos_do_painel
    if configuracao_do_painel.senha_do_painel_confere?(params[:senha])
      session[chave_do_painel] = Time.current.to_i
      redirect_to @textos[:caminho], status: :see_other
    else
      @erro = "Senha de acesso inválida."
      render "compartilhado/painel_tv/senha", status: :unprocessable_content
    end
  end

  def destroy
    session.delete(chave_do_painel)
    redirect_to textos_do_painel[:caminho], status: :see_other
  end

  private

  def chave_do_painel = :"#{controller_path.tr('/', '_')}_liberado_em"
  def liberado? = session[chave_do_painel].to_i > VALIDADE.ago.to_i
end
