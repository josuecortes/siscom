module Core
  # Liga/desliga as notificações push do aparelho em uso (chamado pelo Stimulus `push`).
  class InscricoesPushController < ApplicationController
    def create
      dados = params.expect(inscricao: [ :endpoint, { keys: %i[p256dh auth] } ])

      inscricao = Core::InscricaoPush.find_or_initialize_by(endpoint: dados[:endpoint])
      inscricao.assign_attributes(user: current_user, p256dh: dados.dig(:keys, :p256dh), auth: dados.dig(:keys, :auth),
                                  aparelho: request.user_agent.to_s.truncate(250))

      if inscricao.save
        head :created
      else
        render json: { erros: inscricao.errors.full_messages }, status: :unprocessable_content
      end
    end

    def destroy
      current_user.inscricoes_push.where(endpoint: params[:endpoint].to_s).destroy_all
      head :no_content
    end
  end
end
