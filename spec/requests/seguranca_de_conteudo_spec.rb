require "rails_helper"

RSpec.describe "Política de segurança de conteúdo" do
  it "envia a CSP restrita ao próprio sistema, com nonce nos scripts inline" do
    get new_user_session_path

    csp = response.headers["content-security-policy"]
    nonce = csp[/script-src 'self' 'nonce-([^']+)'/, 1]

    expect(csp).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'none'", "form-action 'self'")
    expect(nonce).to be_present
    expect(response.body).to include(%(<script nonce="#{nonce}">))
    expect(response.body).not_to match(/<script(?![^>]*nonce=)[^>]*>/)
  end
end
