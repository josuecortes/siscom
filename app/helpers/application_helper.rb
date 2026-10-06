module ApplicationHelper
  # Link para um arquivo anexado. Padrão do sistema: abre sempre em nova aba (o navegador mostra imagem e PDF;
  # o que ele não sabe mostrar, baixa).
  def link_do_arquivo(arquivo, classe: "text-[var(--accent-strong)] hover:underline")
    link_to arquivo.filename.to_s, rails_blob_path(arquivo, disposition: "inline"), target: "_blank", rel: "noopener", class: classe, data: { turbo: false }
  end

  # Caminho (só deste sistema) que o painel carrega ao abrir a página: vem de ?painel=/caminho.
  def painel_inicial
    caminho = params[:painel].to_s
    caminho if caminho.match?(%r{\A/(?!/)[^\s\\]*\z})
  end
end
