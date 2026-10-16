# Nome, textos e imagens da marca, vindos das configurações do sistema
# (Administração → Configurações).
module MarcaHelper
  def configuracao_do_sistema
    @configuracao_do_sistema ||= Core::Configuracao.atual
  end

  # Nome usado em títulos de aba, trilhas e metas.
  def nome_do_sistema = configuracao_do_sistema.nome_marca_web

  def favicon_do_sistema
    favicon = configuracao_do_sistema.favicon
    favicon.attached? ? rails_blob_path(favicon, only_path: true) : "/favicon.ico"
  end

  # Sem imagem nas configurações, vale a marca do siscom (a engrenagem com o "S" do sistema antigo), que também é o
  # favicon e o ícone do aplicativo instalado (arquivos em public/, enviados pelo Josue em 2026-10-07, gerados no favicon.io).
  MARCA_PADRAO = "/marca-siscom.png".freeze

  def caminho_do_icone_da_marca
    icone = configuracao_do_sistema.icone_marca
    icone.attached? ? rails_blob_path(icone, only_path: true) : MARCA_PADRAO
  end
end
