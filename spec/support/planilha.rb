require "zip"

# Lê o texto das células de um .xlsx gerado pelo sistema (para conferir o que foi exportado).
module LeituraDePlanilha
  def textos_da_planilha(conteudo)
    xml = +""
    Zip::File.open_buffer(StringIO.new(conteudo)) do |zip|
      zip.glob("xl/{sharedStrings.xml,worksheets/*.xml}").each { |parte| xml << parte.get_input_stream.read.force_encoding(Encoding::UTF_8) << " " }
    end
    xml.scan(%r{<t[^>]*>([^<]*)</t>|<v>([^<]*)</v>}).flatten.compact.map { |texto| CGI.unescapeHTML(texto) }
  end
end

RSpec.configure { |config| config.include LeituraDePlanilha, type: :request }
