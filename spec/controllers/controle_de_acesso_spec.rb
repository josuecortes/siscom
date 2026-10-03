require "rails_helper"

RSpec.describe Core::ControleDeAcesso, type: :controller do
  include_context "com catálogo de exemplo"

  render_views

  controller(ApplicationController) do
    include Core::ExigeModulo

    modulo :fechado

    def index
      pode!("fechado.coisas.editar")
      render plain: "editou"
    end

    def show
      render plain: (pode?("fechado.coisas.editar") ? "pode editar" : "só leitura")
    end
  end

  let(:user) { create(:user) }

  before { sign_in user }

  it "responde 403 com a página de acesso negado para quem não entra no módulo" do
    get :index

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include("Você não tem permissão para acessar esta página.")
  end

  it "responde 403 para quem entra no módulo mas não tem a permissão" do
    create(:core_concessao, user: user, modulo: "fechado", papel: "leitor")

    get :index
    expect(response).to have_http_status(:forbidden)

    get :show, params: { id: 1 }
    expect(response.body).to eq("só leitura")
  end

  it "deixa passar quem tem a permissão" do
    create(:core_concessao, user: user, modulo: "fechado", papel: "admin")

    get :index

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("editou")
  end

  it "responde 403 sem corpo para Turbo Stream" do
    get :index, format: :turbo_stream

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to be_empty
  end

  it "bloqueia o módulo para quem teve o acesso inativado" do
    create(:core_concessao, user: user, modulo: "fechado", papel: "admin")
    Core::Acesso.find_by!(user: user, modulo: "fechado").update!(status: "inativo")

    get :index

    expect(response).to have_http_status(:forbidden)
  end
end
