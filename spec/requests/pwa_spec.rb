require "rails_helper"

RSpec.describe "App instalável (PWA)" do
  it "serve o manifesto com nome, modo de exibição e ícones existentes" do
    get pwa_manifest_path(format: :json)
    manifesto = response.parsed_body

    expect(manifesto).to include("short_name" => "Siscom", "display" => "standalone", "start_url" => "/", "lang" => "pt-BR")
    expect(manifesto["icons"].pluck("sizes", "purpose")).to include([ "192x192", nil ], [ "512x512", nil ], [ "512x512", "maskable" ])
    manifesto["icons"].each { |icone| expect(Rails.public_path.join(icone["src"].delete_prefix("/"))).to exist }
  end

  it "serve o service worker sem exigir login" do
    get pwa_service_worker_path(format: :js)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/javascript")
    expect(response.body).to include('addEventListener("push"', "/sem-conexao.html")
    expect(Rails.public_path.join("sem-conexao.html")).to exist
  end

  it "liga o manifesto e as metas de app nas páginas, inclusive no login" do
    get new_user_session_path

    expect(response.body).to include('rel="manifest" href="/manifest.json"', 'name="theme-color"', "viewport-fit=cover",
                                     'name="apple-mobile-web-app-capable"', "/apple-touch-icon.png")
  end
end
