module Core
  # Apoio aos campos com mapa (Stimulus `mapa`): busca de lugar, endereço de um ponto e as imagens
  # do mapa. Qualquer usuário logado. Porta das rotas geocode, reverse-geocode e map-tiles do seed.
  class MapaController < ApplicationController
    def buscar
      responder Core::Mapa::Nominatim.buscar(params[:q]), chave: :lugares
    end

    def reverso
      responder Core::Mapa::Nominatim.reverso(params[:lat], params[:lon]), chave: :endereco
    end

    def tile
      imagem = Core::Mapa::Tile.buscar(params[:z], params[:x], params[:y])
      return head(:not_found) unless imagem

      expires_in 1.day, public: false
      send_data imagem[:bytes], type: imagem[:tipo], disposition: "inline"
    end

    private

    def responder(resultado, chave:)
      if resultado.sucesso?
        render json: { chave => resultado.objeto }
      else
        render json: { erro: resultado.mensagem_de_erro }, status: :unprocessable_content
      end
    end
  end
end
