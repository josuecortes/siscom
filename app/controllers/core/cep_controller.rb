module Core
  # Consulta de CEP para os formulários com endereço (JSON). Qualquer usuário logado.
  class CepController < ApplicationController
    def show
      resultado = Core::Cep::Consultar.call(params[:cep])

      if resultado.sucesso?
        render json: resultado.objeto
      else
        render json: { erro: resultado.mensagem_de_erro }, status: (resultado.mensagem_de_erro.include?("inválido") ? :unprocessable_content : :not_found)
      end
    end
  end
end
