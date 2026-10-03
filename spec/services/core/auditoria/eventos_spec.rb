require "rails_helper"

# Cada ação administrativa do Core deixa o seu registro de auditoria.
RSpec.describe "Eventos de auditoria do Core" do # rubocop:disable RSpec/DescribeClass
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:alvo) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", password: "Senha@Forte123") }

  def ultimo = Core::RegistroAuditoria.recentes.first

  def eventos = Core::RegistroAuditoria.order(:id).pluck(:evento)

  it "cadastro e edição de usuário" do
    novo = Core::Usuarios::Criar.call(atributos: { nome: "Ana", email: "ana@seed.ap.gov.br" }, criado_por: superadmin).objeto
    expect(ultimo).to have_attributes(evento: "usuario.criado", ator: superadmin, alvo_id: novo.id, dados: { "email" => "ana@seed.ap.gov.br" })

    Core::Usuarios::Atualizar.call(user: novo, atributos: { nome: "Ana Paula" }, atualizado_por: superadmin)
    expect(ultimo.dados).to eq("mudancas" => { "nome" => { "de" => "ANA", "para" => "ANA PAULA" } })
  end

  it "edição sem mudança não gera registro" do
    expect { Core::Usuarios::Atualizar.call(user: alvo, atributos: { nome: alvo.nome }, atualizado_por: superadmin) }
      .not_to change(Core::RegistroAuditoria, :count)
  end

  it "ativar, desativar e redefinir senha (sem guardar a senha)" do
    Core::Usuarios::AlterarStatus.call(user: alvo, ativo: false, alterado_por: superadmin)
    Core::Usuarios::AlterarStatus.call(user: alvo, ativo: true, alterado_por: superadmin)
    temporaria = Core::Usuarios::RedefinirSenha.call(user: alvo, redefinido_por: superadmin).objeto

    expect(eventos).to eq(%w[usuario.desativado usuario.ativado usuario.senha_redefinida])
    expect(Core::RegistroAuditoria.pluck(:dados).to_json).not_to include(temporaria)
  end

  it "troca de senha pelo próprio usuário" do
    alvo.update!(deve_trocar_senha: true)

    Core::Usuarios::TrocarSenha.call(user: alvo, senha_atual: "Senha@Forte123", nova_senha: "Nova@Senha456", confirmacao: "Nova@Senha456")

    expect(ultimo).to have_attributes(evento: "usuario.senha_alterada", ator: alvo, dados: { "troca_obrigatoria" => true })
  end

  it "papéis e módulos" do
    concessao = Core::Acessos::Conceder.call(user: alvo, modulo: "core", papel: "auditor", concedido_por: superadmin).objeto
    Core::Acessos::Conceder.call(user: alvo, modulo: "core", papel: "auditor", concedido_por: superadmin) # repetida: sem registro
    Core::Acessos::Revogar.call(concessao: concessao, revogado_por: superadmin)
    Core::Acessos::AlterarModulo.call(user: alvo, modulo: "core", ativo: false, alterado_por: superadmin)
    Core::Acessos::AlterarModulo.call(user: alvo, modulo: "core", ativo: true, alterado_por: superadmin)

    expect(eventos).to eq(%w[acesso.papel_concedido acesso.papel_revogado acesso.modulo_bloqueado acesso.modulo_liberado])
    expect(Core::RegistroAuditoria.order(:id).first.dados).to eq("modulo" => "core", "papel" => "auditor")
  end

  it "ações que falham não deixam registro" do
    expect { Core::Usuarios::AlterarStatus.call(user: alvo, ativo: false, alterado_por: create(:user)) }
      .not_to change(Core::RegistroAuditoria, :count)
  end

  it "todo evento registrado pelo Core tem rótulo traduzido" do
    fontes = Rails.root.glob("app/{services,controllers}/core/**/*.rb").map(&:read).join
    eventos_no_codigo = fontes.scan(/evento: "core\.([a-z_]+)\.([a-z_#{}@? ':]+)"/).reject { |_, acao| acao.include?("#") }

    expect(eventos_no_codigo).not_to be_empty
    eventos_no_codigo.each do |objeto, acao|
      expect(I18n.exists?("auditoria.eventos.core.#{objeto}.#{acao}")).to be(true), "falta rótulo para core.#{objeto}.#{acao}"
    end
  end
end
