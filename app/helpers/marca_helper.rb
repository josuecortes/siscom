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

  def caminho_do_icone_da_marca
    icone = configuracao_do_sistema.icone_marca
    rails_blob_path(icone, only_path: true) if icone.attached?
  end
end
