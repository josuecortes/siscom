module ApplicationHelper
  # Caminho (só deste sistema) que o painel carrega ao abrir a página: vem de ?painel=/caminho.
  def painel_inicial
    caminho = params[:painel].to_s
    caminho if caminho.match?(%r{\A/(?!/)[^\s\\]*\z})
  end
end
