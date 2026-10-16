module Core
  # Login (Devise). Quem entra com a senha padrão antiga do siscom ("Seed@123")
  # fica obrigado a trocar a senha antes de usar o sistema.
  class SessoesController < Devise::SessionsController
    layout "publico"

    def create
      super do |user|
        Core::Auditoria::Registrar.call(evento: "core.sessao.iniciada", alvo: user, ator: user)
        if Core::PoliticaDeSenha.padrao_antiga?(params.dig(:user, :password)) && !user.deve_trocar_senha?
          user.update_column(:deve_trocar_senha, true) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
