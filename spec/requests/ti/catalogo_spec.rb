require "rails_helper"

RSpec.describe "TI: catálogo (categorias, perfis de abertura e grupos técnicos)" do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }
  let(:supervisor) { create(:user, nome: "SUPERVISOR DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") } }
  let(:tecnico) { create(:user, nome: "TECNICO DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let!(:maria) { create(:user, nome: "MARIA OLIVEIRA") }

  it "técnico não gerencia o catálogo" do
    grupo = create(:ti_grupo_tecnico)
    sign_in tecnico

    respostas = [
      -> { get ti_categorias_path },
      -> { post ti_perfis_abertura_path, params: { registro: { nome: "X" } } },
      -> { patch desativar_ti_grupo_tecnico_path(grupo) },
      -> { get edit_ti_grupo_tecnico_membros_path(grupo) },
      -> { patch ti_grupo_tecnico_membros_path(grupo), params: { user_ids: [ tecnico.id ] } },
      -> { patch ti_permissao_perfis_abertura_path(maria), params: { perfil_ids: [] } }
    ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
    expect(grupo.reload).to be_ativo
  end

  context "com supervisor (gerencia o catálogo, não as permissões)" do
    before { sign_in supervisor }

    it "abre os três itens pela mesma tela" do
      { ti_categorias_path => "Categorias de solicitação", ti_perfis_abertura_path => "Perfis de abertura",
        ti_grupos_tecnicos_path => "Grupos técnicos" }.each do |caminho, titulo|
        get caminho
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<title>#{titulo} · Siscom</title>")
      end
    end

    it "cria, edita, busca e muda o status, com auditoria" do
      post ti_categorias_path, params: { registro: { nome: "sistemas web", descricao: "Sistemas da SEED" } }
      categoria = Ti::Categoria.find_by!(nome: "SISTEMAS WEB")
      expect(response).to redirect_to(ti_categorias_path)

      patch ti_categoria_path(categoria), params: { registro: { nome: "Sistemas" } }
      patch desativar_ti_categoria_path(categoria)
      expect(categoria.reload).to have_attributes(nome: "SISTEMAS", descricao: "Sistemas da SEED", status: "inativo")
      expect(Core::RegistroAuditoria.where(modulo: "ti").order(:id).pluck(:evento)).to eq(%w[catalogo.criado catalogo.atualizado catalogo.desativado])

      get ti_categorias_path, params: { q: "sist", status: "inativo" }
      expect(response.body).to include("1 categoria(s) registrada(s)", "Inativa")
    end

    it "mostra erro de nome repetido com 422" do
      create(:ti_perfil_abertura, nome: "Diretor de escola")

      post ti_perfis_abertura_path, params: { registro: { nome: "diretor de escola" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome já está em uso")
    end

    it "grupo técnico guarda se os membros podem pegar chamados da fila" do
      post ti_grupos_tecnicos_path, params: { registro: { nome: "Redes", permite_autoatribuicao: "0" } }

      expect(Ti::GrupoTecnico.sole).to have_attributes(nome: "REDES", permite_autoatribuicao: false)
    end

    it "mostra no painel de membros só quem tem permissão na TI" do
      grupo = create(:ti_grupo_tecnico, nome: "Redes")
      tecnico

      get edit_ti_grupo_tecnico_membros_path(grupo)

      expect(response.body).to include("Gerenciar membros de REDES", "TECNICO DA TI", "SUPERVISOR DA TI")
      expect(response.body).not_to include("MARIA OLIVEIRA")
    end

    it "define os membros do grupo, avisa quem entrou e audita" do
      grupo = create(:ti_grupo_tecnico, nome: "Redes")

      patch ti_grupo_tecnico_membros_path(grupo), params: { user_ids: [ "", tecnico.id, maria.id ] }
      expect(grupo.membros).to contain_exactly(tecnico)
      expect(tecnico.notificacoes.sole.mensagem).to include("grupo técnico REDES")

      patch ti_grupo_tecnico_membros_path(grupo), params: { user_ids: [ "", supervisor.id ] }
      expect(grupo.reload.membros).to contain_exactly(supervisor)
      expect(Core::RegistroAuditoria.where(evento: "grupo_tecnico.membros_alterados").count).to eq(2)

      get ti_grupos_tecnicos_path
      expect(Nokogiri::HTML(response.body).css("##{ActionView::RecordIdentifier.dom_id(grupo)} td")[3].text).to eq("1")
    end

    it "não mexe nos perfis de abertura dos usuários" do
      perfil = create(:ti_perfil_abertura)

      patch ti_permissao_perfis_abertura_path(maria), params: { perfil_ids: [ perfil.id ] }

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "com administrador" do
    before { sign_in admin }

    it "define os perfis de abertura do usuário e mostra na lista de permissões" do
      diretor = create(:ti_perfil_abertura, nome: "Diretor de escola")
      sede = create(:ti_perfil_abertura, nome: "Servidor da sede")
      antigo = create(:ti_perfil_abertura, nome: "Antigo", status: "inativo")
      Ti::PerfilUsuario.create!(user: maria, perfil_abertura: antigo)

      get edit_ti_permissao_perfis_abertura_path(maria)
      expect(response.body).to include("Gerenciar perfis de MARIA OLIVEIRA", "DIRETOR DE ESCOLA", "SERVIDOR DA SEDE")
      expect(response.body).not_to include("ANTIGO")

      patch ti_permissao_perfis_abertura_path(maria), params: { perfil_ids: [ "", diretor.id, sede.id ] }
      patch ti_permissao_perfis_abertura_path(maria), params: { perfil_ids: [ "", sede.id ] }

      expect(Ti::PerfilUsuario.where(user: maria).map(&:perfil_abertura)).to contain_exactly(sede, antigo)
      get ti_permissoes_path, params: { q: "maria" }
      expect(response.body).to include("SERVIDOR DA SEDE")
      expect(Core::RegistroAuditoria.where(evento: "perfil_abertura.usuario_alterado").count).to eq(2)
    end
  end
end
