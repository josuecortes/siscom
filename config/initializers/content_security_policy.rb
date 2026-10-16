# Política de segurança de conteúdo: só recursos do próprio sistema.
# Scripts e estilos inline precisam do nonce (javascript_tag nonce: true,
# importmap e Turbo já usam o nonce da meta tag csp-nonce).
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self
    policy.img_src     :self, :data, :blob
    policy.font_src    :self, :data
    policy.connect_src :self, *(Rails.env.production? ? [] : [ "ws://localhost:*", "ws://127.0.0.1:*" ])
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Nonce estável por sessão (compatível com a navegação do Turbo Drive).
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s.presence || SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
