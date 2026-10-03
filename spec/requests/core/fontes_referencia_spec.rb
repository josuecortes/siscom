require "rails_helper"

RSpec.describe "Administração: fontes de referência" do
  let(:superadmin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:admin_usuarios) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:fonte) { Core::FontesReferencia::Publicar.call.sole }

  it "exige a permissão core.fontes_referencia.gerenciar" do
    sign_in admin_usuarios

    respostas = [
      -> { get core_fontes_referencia_path },
      -> { get new_core_fonte_referencia_path },
      -> { post core_fontes_referencia_path, params: { fonte: { nome: "X" } } },
      -> { patch desativar_core_fonte_referencia_path(fonte) }
    ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com superadministrador" do
    before { sign_in superadmin }

    it "publica e lista as fontes padrão ao abrir a tela" do
      get core_fontes_referencia_path

      expect(response.body).to include("1 fonte(s) registrada(s)", "Administração &gt; Usuários", "core_usuarios", "Gerenciada pelo sistema",
                                       "Seleção única e Seleção múltipla")
    end

    it "preenche o formulário de nova fonte com os padrões da entidade escolhida" do
      get new_core_fonte_referencia_path, params: { entidade: "core:usuarios" }

      expect(response.body).to include('value="Administração &gt; Usuários"', 'id="fonte_campos_busca_email"')
      expect(response.body).to match(/<option selected="selected" value="nome">nome/)
    end

    it "cria, edita e muda o status" do
      post core_fontes_referencia_path, params: { fonte: { nome: "Usuários por e-mail", entidade_completa: "core:usuarios", campo_rotulo: "email",
                                                           campo_valor: "id", campos_busca: [ "email" ], tipos_de_campo: [ "selecao_unica" ] } }
      nova = Core::FonteReferencia.find_by!(chave: "usu_rios_por_e_mail")
      expect(response).to redirect_to(core_fontes_referencia_path)

      patch core_fonte_referencia_path(nova), params: { fonte: { nome: "E-mails", campos_busca: [ "email", "nome" ] } }
      expect(nova.reload).to have_attributes(nome: "E-mails", campos_busca: %w[email nome], chave: "usu_rios_por_e_mail")

      patch desativar_core_fonte_referencia_path(nova)
      expect(nova.reload).to be_inativo
      patch ativar_core_fonte_referencia_path(nova)
      expect(nova.reload).to be_ativo
    end

    it "mostra os erros com 422" do
      post core_fontes_referencia_path, params: { fonte: { nome: "", entidade_completa: "core:usuarios", campo_rotulo: "nome", campo_valor: "id" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Revise os campos destacados", "Campos de busca deve ter ao menos um campo")
    end

    it "avisa que a fonte do sistema não muda de estrutura" do
      patch core_fonte_referencia_path(fonte), params: { fonte: { campo_rotulo: "email" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("gerenciada pelo sistema e não pode ter a estrutura alterada")
    end
  end
end
