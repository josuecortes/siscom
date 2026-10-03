require "rails_helper"

RSpec.describe "RH: acessos e pendências" do
  let(:admin) { create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") } }
  let(:operador) { create(:user, nome: "OPERADOR DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }
  let!(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  describe "acessos" do
    it "só quem tem rh.acessos.conceder entra" do
      sign_in operador

      respostas = [ -> { get rh_acessos_path }, -> { get edit_rh_acesso_path(maria) }, -> { patch rh_acesso_path(maria), params: { papel: "leitor" } } ]
                  .map { |requisicao| requisicao.call && response.status }

      expect(respostas).to all(eq(403))
      expect(Core::Concessao.where(user: maria)).to be_empty
    end

    context "com administrador do RH" do
      before { sign_in admin }

      it "lista todos os usuários ativos com as permissões e filtra" do
        operador

        get rh_acessos_path
        expect(response.body).to include("MARIA OLIVEIRA", "Sem permissão (só a própria ficha)", "OPERADOR DO RH", "Operador", "3 usuário(s) listado(s)")

        get rh_acessos_path, params: { situacao: "sem" }
        expect(response.body).to include("MARIA OLIVEIRA", "1 usuário(s) listado(s)")

        get rh_acessos_path, params: { situacao: "com", q: "operador" }
        expect(response.body).to include("OPERADOR DO RH", "1 usuário(s) listado(s)")
      end

      it "dá, troca e tira a permissão: sempre uma só" do
        patch rh_acesso_path(maria), params: { papel: "leitor" }
        expect(Core::Autorizacao.new(maria).papeis(:rh)).to contain_exactly("leitor", "usuario")

        patch rh_acesso_path(maria), params: { papel: "operador" }
        expect(Core::Api.papeis_concedidos([ maria.id ], modulo: :rh)).to eq(maria.id => [ "operador" ])

        patch rh_acesso_path(maria), params: { papel: "" }
        expect(Core::Autorizacao.new(maria).papeis(:rh)).to eq([ "usuario" ])
        expect(response).to redirect_to(rh_acessos_path)
      end

      it "avisa a pessoa e registra na auditoria" do
        patch rh_acesso_path(maria), params: { papel: "leitor" }

        expect(maria.notificacoes.sole.mensagem).to include("Papel Leitor no módulo RH")
        expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "acesso.papel_concedido", ator: admin, alvo_id: maria.id)
      end

      it "ignora papel que não é do RH ou é automático" do
        patch rh_acesso_path(maria), params: { papel: "superadmin" }
        patch rh_acesso_path(maria), params: { papel: "usuario" }

        expect(Core::Concessao.where(user: maria)).to be_empty
      end
    end
  end

  describe "pendências" do
    let(:pessoa) { create(:rh_pessoa, nome: "Maria Oliveira", cpf: nil, celular: "96991234567", user: maria) }
    let!(:pendencia) { Rh::PendenciaImportacao.create!(pessoa: pessoa, tipo: "cpf_vazio", descricao: "Sem CPF no cadastro antigo.") }

    it "leitor não vê pendências" do
      sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "leitor") }

      get rh_pendencias_path

      expect(response).to have_http_status(:forbidden)
    end

    context "com operador" do
      before { sign_in operador }

      it "lista as abertas, com totais por tipo, busca e filtro" do
        Rh::PendenciaImportacao.create!(pessoa: create(:rh_pessoa, nome: "Joao Santos"), tipo: "nome_sem_sobrenome", descricao: "x")

        get rh_pendencias_path
        expect(response.body).to include("2 pendência(s) em aberto", "CPF não informado (1)", "Todas (2)", "MARIA OLIVEIRA", "JOAO SANTOS")

        get rh_pendencias_path, params: { tipo: "cpf_vazio" }
        expect(response.body).to include("1 pendência(s) em aberto")
        expect(response.body).not_to include("JOAO SANTOS")

        get rh_pendencias_path, params: { q: "joao" }
        expect(response.body).not_to include("MARIA OLIVEIRA")
      end

      it "marca como resolvida à mão" do
        patch resolver_rh_pendencia_path(pendencia)

        expect(pendencia.reload.resolvida_em).to be_present
        expect(Core::RegistroAuditoria.recentes.first).to have_attributes(modulo: "rh", evento: "pendencia.resolvida", ator: operador)
      end

      it "resolve sozinha quando o CPF é informado na ficha" do
        patch rh_pessoa_path(pessoa), params: { pessoa: { cpf: "529.982.247-25" } }

        expect(pendencia.reload.resolvida_em).to be_present
        get rh_pendencias_path
        expect(response.body).to include("0 pendência(s) em aberto")
      end
    end
  end
end
