module Core
  # Envio de mensagem numa conversa. A mensagem chega a todos por Turbo Streams; a resposta só
  # limpa o campo de quem enviou (ou mostra o erro).
  class MensagensController < ApplicationController
    def create
      conversa = Core::Conversa.find(params[:conversa_id])
      resultado = Conversas::EnviarMensagem.call(conversa: conversa, autor: current_user, corpo: params[:corpo])

      render turbo_stream: turbo_stream.replace("formulario_da_conversa_#{conversa.id}", partial: "core/conversas/formulario",
                                                locals: { conversa: conversa, erro: (resultado.mensagem_de_erro if resultado.falha?), corpo: (params[:corpo] if resultado.falha?) }),
             status: (resultado.sucesso? ? :ok : :unprocessable_content)
    end
  end
end
