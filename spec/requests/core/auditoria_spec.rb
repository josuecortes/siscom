require "rails_helper"

RSpec.describe "Administração: auditoria" do
  let(:auditor) { create(:user, nome: "AUDITOR SOUZA").tap { |u| create(:core_concessao, user: u, papel: "auditor") } }
  let(:admin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  def registrar(evento, alvo, ator, em: Time.current, dados: {})
    travel_to(em) { Core::Auditoria::Registrar.call(evento: evento, alvo: alvo, ator: ator, dados: dados) }
  end

  it "exige a permissão core.auditoria.ver" do
    sign_in admin # administrador de usuários não é auditor

    get core_auditoria_path

    expect(response).to have_http_status(:forbidden)
  end

  context "com auditor" do
    before do
      registrar("core.usuario.atualizado", maria, admin, em: 3.days.ago,
                                                         dados: { mudancas: { nome: { de: "MARIA", para: "MARIA OLIVEIRA" } } })
      registrar("core.acesso.papel_concedido", maria, admin, em: 1.day.ago, dados: { modulo: "core", papel: "auditor" })
      registrar("core.usuario.desativado", auditor, nil)
      sign_in auditor
    end

    it "lista os registros com rótulo, ator, afetado e detalhes" do
      get core_auditoria_path

      expect(response.body).to include("3 registro(s) de auditoria", "Usuário atualizado", "ADMIN DA SILVA", "MARIA OLIVEIRA",
                                       "Nome: MARIA → MARIA OLIVEIRA", "Administração · Auditor", "Sistema")
    end

    it "filtra por texto, evento e período" do
      get core_auditoria_path, params: { q: "auditor souza" }
      expect(response.body).to include("1 registro(s)", "Usuário desativado")

      get core_auditoria_path, params: { evento: "core.acesso.papel_concedido" }
      expect(response.body).to include("1 registro(s)", "Permissão concedida")

      get core_auditoria_path, params: { de: 2.days.ago.strftime("%d/%m/%Y"), ate: Date.current.strftime("%d/%m/%Y") }
      expect(response.body).to include("2 registro(s)", %(value="#{Date.current.strftime('%d/%m/%Y')}"))
      expect(response.body).not_to include("Usuário atualizado</p>")
    end

    it "ignora filtros inválidos" do
      get core_auditoria_path, params: { evento: "core.nada.existe", de: "ontem" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("3 registro(s)")
    end

    it "mostra o item Auditoria no menu" do
      get core_auditoria_path

      expect(response.body).to include(%(href="#{core_auditoria_path}"))
    end
  end

  describe "registro automático nas telas" do
    it "guarda quem fez, o IP e a requisição ao desativar um usuário" do
      sign_in admin

      patch desativar_core_usuario_path(maria)

      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(
        evento: "usuario.desativado", ator: admin, alvo_id: maria.id, ip: "127.0.0.1", request_id: be_present
      )
    end

    it "registra a entrada no sistema" do
      post user_session_path, params: { user: { email: maria.email, password: "Senha@Forte123" } }

      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "sessao.iniciada", ator: maria, ip: "127.0.0.1")
    end
  end

  describe "histórico na tela Trocar senha" do
    it "mostra as trocas e redefinições do próprio usuário" do
      registrar("core.usuario.senha_redefinida", maria, admin)
      registrar("core.usuario.senha_redefinida", admin, nil)
      sign_in maria

      get edit_minha_senha_path

      expect(response.body).to include("Histórico de trocas de senha", "Redefinição de senha", "ADMIN DA SILVA")
      expect(response.body.scan("Redefinição de senha").size).to eq(1)
    end
  end
end
