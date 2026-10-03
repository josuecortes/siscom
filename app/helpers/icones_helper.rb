# Ícones CoreUI (licença MIT/CC BY 4.0) em SVG inline, herdando a cor do texto.
# Arquivos em app/assets/images/icones/cil-<nome>.svg.
#
#   icone(:moon)                          # decorativo (aria-hidden)
#   icone(:user, classe: "h-5 w-5")
#   icone(:bell, titulo: "Notificações")  # com nome acessível
module IconesHelper
  PASTA_ICONES = Rails.root.join("app/assets/images/icones")

  def icone(nome, classe: "h-4 w-4", titulo: nil)
    atributos = { class: classe }
    atributos.merge!(titulo ? { role: "img", "aria-label": titulo } : { "aria-hidden": "true" })
    html = atributos.map { |chave, valor| %(#{chave}="#{ERB::Util.html_escape(valor)}") }.join(" ")

    # SVG lido de arquivo local do projeto; atributos escapados acima.
    IconesHelper.svg(nome.to_s.tr("_", "-")).sub("<svg ", "<svg #{html} ").html_safe # rubocop:disable Rails/OutputSafety
  end

  def self.svg(nome)
    @svgs ||= {}
    @svgs.delete(nome) if Rails.env.development?
    @svgs[nome] ||= begin
      caminho = PASTA_ICONES.join("cil-#{nome}.svg")
      raise ArgumentError, "ícone desconhecido: #{nome}" unless caminho.exist?

      caminho.read.strip.gsub(/\s*\n\s*/, " ")
    end
  end
end
