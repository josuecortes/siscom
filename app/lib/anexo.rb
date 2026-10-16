# Limite de tamanho de todo arquivo enviado ao sistema (anexos de solicitações, observações, documento de viagem,
# foto de perfil, imagens da marca): sempre até 1 MB. Regra do Josue (2026-10-07).
#
# No navegador, app/javascript/arquivos.js reduz sozinho as imagens grandes (foto de celular) para caber no limite
# e recusa na hora o documento que passa dele; aqui é a conferência do servidor, que vale sempre.
module Anexo
  TAMANHO_MAXIMO = 1.megabyte
  LIMITE = "1 MB".freeze

  module_function

  # Aceita um arquivo enviado (upload) ou um blob já gravado.
  def grande?(arquivo) = (arquivo.respond_to?(:byte_size) ? arquivo.byte_size : arquivo.size) > TAMANHO_MAXIMO
end
