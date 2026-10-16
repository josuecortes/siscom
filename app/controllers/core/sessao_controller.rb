module Core
  # Pulso da sessão (app/javascript/sessao.js): mantém viva a sessão de quem está preenchendo um formulário e
  # devolve o token de formulário atual. Com a sessão expirada o Devise responde 401, e o navegador avisa a
  # pessoa sem perder o que ela preencheu.
  class SessaoController < ApplicationController
    skip_before_action :exigir_troca_de_senha

    def pulso
      response.headers["Cache-Control"] = "no-store"
      render json: { token: form_authenticity_token }
    end
  end
end
