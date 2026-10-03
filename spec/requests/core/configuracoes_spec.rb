require "rails_helper"

RSpec.describe "Administração: configurações" do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:admin_usuarios) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }

  def salvar(atributos = {}, extras = {})
    patch core_configuracoes_path, params: { configuracao: atributos }.merge(extras)
  end

  it "exige a permissão core.configuracoes.gerenciar" do
    sign_in admin_usuarios

    respostas = [ -> { get core_configuracoes_path }, -> { salvar(nome_marca_web: "Outro") } ].map { |r| r.call && response.status }

    expect(respostas).to all(eq(403))
    expect(Core::Configuracao.atual.nome_marca_web).to eq("Siscom")
  end

  it "o login usa os nomes e o título das configurações, sem precisar de login" do
    Core::Configuracao.atual.update!(nome_marca_web: "Siscom Web", nome_marca_celular: "Siscom Cel", titulo_login: "Educação")

    get new_user_session_path

    expect(response.body).to include("Siscom Web", "Siscom Cel", "Educação", "<title>Entrar · Siscom Web</title>")
  end

  context "com superadministrador" do
    before { sign_in superadmin }

    it "mostra o formulário com os valores padrão" do
      get core_configuracoes_path

      expect(response.body).to include("Marca e cabeçalho", "Nome da marca (computador) *", 'value="Siscom"', 'value="Seed"')
    end

    it "salva os textos e eles aparecem no menu, no topo e no manifesto do app" do
      salvar(nome_marca_web: "  Portal   SEED ", nome_cabecalho_web: "Portal da Educação", nome_marca_celular: "Portal")
      expect(response).to redirect_to(core_configuracoes_path)

      get root_path
      expect(response.body).to include("Portal SEED", "Portal da Educação", "<title>Início · Portal SEED</title>")

      get pwa_manifest_path(format: :json)
      expect(response.parsed_body).to include("short_name" => "Portal", "name" => "Portal SEED · SEED")
    end

    it "esconde nomes e ícone conforme as opções" do
      salvar(mostrar_nome_cabecalho_web: "0", mostrar_nome_cabecalho_celular: "0", mostrar_icone_marca_web: "0",
             nome_cabecalho_web: "Nome Escondido")

      get root_path

      expect(response.body).not_to include("Nome Escondido")
    end

    it "troca e remove o ícone da marca e o favicon" do
      salvar({ icone_marca: fixture_file_upload("avatar.png", "image/png"), favicon: fixture_file_upload("avatar.png", "image/png") })
      configuracao = Core::Configuracao.atual
      expect(configuracao.icone_marca).to be_attached
      expect(configuracao.favicon).to be_attached

      get root_path
      expect(response.body).to include(%(rel="icon" href="/rails/active_storage/blobs/))

      salvar({ nome_marca_web: "Siscom" }, remover: { favicon: "1" })
      expect(Core::Configuracao.atual.favicon).not_to be_attached
      expect(Core::Configuracao.atual.icone_marca).to be_attached
    end

    it "recusa arquivo que não é imagem e nome em branco, com 422" do
      salvar(nome_marca_web: "", icone_marca: fixture_file_upload("documento.txt", "text/plain"))

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Revise os campos destacados", "deve ser uma imagem PNG, WebP, JPG ou ICO")
      expect(Core::Configuracao.atual.reload).to have_attributes(nome_marca_web: "Siscom")
      expect(Core::Configuracao.atual.icone_marca).not_to be_attached
    end

    it "registra na auditoria o que mudou" do
      salvar(titulo_login: "Educação")

      registro = Core::RegistroAuditoria.recentes.first
      expect(registro).to have_attributes(evento: "configuracao.atualizada", ator: superadmin, alvo_descricao: "Configurações do sistema")
      expect(registro.dados["mudancas"]).to eq("titulo_login" => { "de" => "Seed", "para" => "Educação" })
    end

    it "salvar sem mudar nada não gera auditoria" do
      expect { salvar(nome_marca_web: "Siscom") }.not_to change(Core::RegistroAuditoria, :count)
    end
  end
end
