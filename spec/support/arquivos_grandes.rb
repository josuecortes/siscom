require "zlib"

# Arquivos de teste acima do limite de 1 MB, criados na hora (não ficam no repositório).
module ArquivosGrandes
  # PNG válido de `lado` x `lado` com ruído (não comprime): 700 px dá ~1,4 MB.
  def png_grande(lado: 700)
    linhas = Array.new(lado) { "\x00".b + Random.bytes(lado * 3) }.join
    pedaco = ->(tipo, dados) { [ dados.bytesize ].pack("N") + tipo + dados + [ Zlib.crc32(tipo + dados) ].pack("N") }
    conteudo = "\x89PNG\r\n\x1A\n".b + pedaco.call("IHDR", [ lado, lado, 8, 2, 0, 0, 0 ].pack("NNCCCCC")) + pedaco.call("IDAT", Zlib::Deflate.deflate(linhas, 1)) + pedaco.call("IEND", "")
    arquivo_temporario("foto-grande.png", conteudo)
  end

  def pdf_grande(bytes: 1.megabyte + 1) = arquivo_temporario("oficio-grande.pdf", "%PDF-1.4\n".b + ("0" * bytes))

  def arquivo_temporario(nome, conteudo)
    caminho = Rails.root.join("tmp", "spec-#{SecureRandom.hex(4)}-#{nome}")
    File.binwrite(caminho, conteudo)
    (@arquivos_temporarios ||= []) << caminho
    caminho
  end
end

RSpec.configure do |config|
  config.include ArquivosGrandes
  config.after { Array(@arquivos_temporarios).each { |caminho| FileUtils.rm_f(caminho) } }
end
