require "rails_helper"

RSpec.describe "TI: solicitações do catálogo" do
  let(:supervisor) { create(:user, nome: "SUPERVISOR DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") } }
  let(:tecnico) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let(:rede) { create(:ti_categoria, nome: "Rede") }

  it "técnico não gerencia solicitações" do
    solicitacao = create(:ti_problema)
    sign_in tecnico

    respostas = [
      -> { get ti_solicitacoes_path },
      -> { post ti_solicitacoes_path, params: { solicitacao: { nome: "X", descricao: "Y", categoria_id: rede.id } } },
      -> { patch desativar_ti_solicitacao_path(solicitacao) },
      -> { patch ti_solicitacao_perfis_path(solicitacao), params: { ids: [] } },
      -> { get edit_ti_solicitacao_grupos_path(solicitacao) }
    ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com supervisor" do
    before { sign_in supervisor }

    it "cria, edita e muda o status, com auditoria" do
      post ti_solicitacoes_path, params: { solicitacao: { nome: "sem internet", descricao: "Computador sem acesso à internet", categoria_id: rede.id,
                                                          exige_triagem: "0", permite_varios_abertos: "1", prioridade_padrao: "alta" } }
      solicitacao = Ti::Problema.sole
      expect(response).to redirect_to(ti_solicitacoes_path)
      expect(solicitacao).to have_attributes(nome: "SEM INTERNET", categoria: rede, exige_triagem: false, permite_varios_abertos: true, prioridade_padrao: "alta")

      patch ti_solicitacao_path(solicitacao), params: { solicitacao: { nome: "Sem rede" } }
      patch desativar_ti_solicitacao_path(solicitacao)

      expect(solicitacao.reload).to have_attributes(nome: "SEM REDE", status: "inativo")
      expect(Core::RegistroAuditoria.where(modulo: "ti").order(:id).pluck(:evento)).to eq(%w[solicitacao.criada solicitacao.atualizada catalogo.desativado])
    end

    it "exige categoria, nome e resumo; o nome não repete na mesma categoria" do
      create(:ti_problema, nome: "Sem internet", categoria: rede)

      post ti_solicitacoes_path, params: { solicitacao: { nome: "sem internet", descricao: "", categoria_id: rede.id } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome já está em uso", "não pode ficar em branco")

      post ti_solicitacoes_path, params: { solicitacao: { nome: "Outra", descricao: "Resumo", categoria_id: "" } }
      expect(response.body).to include("Categoria deve ser escolhida")
    end

    it "lista com categoria, quem abre e quem atende; busca por nome ou categoria" do
      solicitacao = create(:ti_problema, nome: "Sem internet", categoria: rede)
      solicitacao.perfis_abertura << create(:ti_perfil_abertura, nome: "Geral")
      solicitacao.grupos_tecnicos << create(:ti_grupo_tecnico, nome: "Redes")
      create(:ti_problema, nome: "Impressora parada", categoria: create(:ti_categoria, nome: "Hardware"))

      get ti_solicitacoes_path
      expect(response.body).to include("2 solicitação(ões) registrada(s)", "SEM INTERNET", "GERAL", "REDES", "Sem perfis", "Sem grupos")

      get ti_solicitacoes_path, params: { q: "hardw" }
      expect(response.body).to include("1 solicitação(ões) registrada(s)", "IMPRESSORA PARADA")
    end

    it "define os perfis de abertura e os grupos técnicos da solicitação" do
      solicitacao = create(:ti_problema, nome: "Sem internet")
      geral = create(:ti_perfil_abertura, nome: "Geral", padrao: true)
      escola = create(:ti_perfil_abertura, nome: "Escola")
      redes = create(:ti_grupo_tecnico, nome: "Redes")

      get edit_ti_solicitacao_perfis_path(solicitacao)
      expect(response.body).to include("Perfis de abertura de SEM INTERNET", "GERAL (padrão: todos os usuários)", "ESCOLA")

      patch ti_solicitacao_perfis_path(solicitacao), params: { ids: [ "", geral.id, escola.id ] }
      patch ti_solicitacao_perfis_path(solicitacao), params: { ids: [ "", escola.id ] }
      patch ti_solicitacao_grupos_path(solicitacao), params: { ids: [ "", redes.id ] }

      expect(solicitacao.reload).to have_attributes(perfis_abertura: [ escola ], grupos_tecnicos: [ redes ])
      expect(Core::RegistroAuditoria.where(evento: %w[solicitacao.perfis_alterados solicitacao.grupos_alterados]).count).to eq(3)
    end

    it "define as solicitações pelo lado do perfil de abertura e do grupo técnico" do
      internet, impressora = create(:ti_problema, nome: "Sem internet", categoria: rede), create(:ti_problema, nome: "Impressora parada", categoria: rede)
      inativa = create(:ti_problema, status: "inativo")
      escola = create(:ti_perfil_abertura, nome: "Escola").tap { |perfil| perfil.problemas << inativa }
      redes = create(:ti_grupo_tecnico, nome: "Redes")

      get edit_ti_perfil_abertura_solicitacoes_path(escola)
      expect(response.body).to include("Solicitações de ESCOLA", "REDE", "SEM INTERNET", "IMPRESSORA PARADA")

      patch ti_perfil_abertura_solicitacoes_path(escola), params: { ids: [ "", internet.id, impressora.id ] }
      patch ti_perfil_abertura_solicitacoes_path(escola), params: { ids: [ "", internet.id ] }
      patch ti_grupo_tecnico_solicitacoes_path(redes), params: { ids: [ "", impressora.id ] }

      expect(escola.reload.problemas).to contain_exactly(internet, inativa)
      expect(redes.reload.problemas).to contain_exactly(impressora)
      expect(response).to redirect_to(ti_grupos_tecnicos_path)
      expect(Core::RegistroAuditoria.where(evento: "catalogo.solicitacoes_alteradas").count).to eq(3)
    end

    it "marca um perfil de abertura como padrão e mostra Todos na lista" do
      post ti_perfis_abertura_path, params: { registro: { nome: "Geral", padrao: "1" } }

      expect(Ti::PerfilAbertura.sole).to have_attributes(nome: "GERAL", padrao: true)
      get ti_perfis_abertura_path
      expect(Nokogiri::HTML(response.body).css("tbody td").map { |celula| celula.text.strip }).to include("Todos")
    end
  end

  describe "Ti::Problema.que_pode_abrir" do
    it "junta as solicitações dos perfis padrão com as dos perfis do usuário, só as ativas" do
      maria = create(:user)
      geral = create(:ti_perfil_abertura, padrao: true)
      escola = create(:ti_perfil_abertura)
      sistemas = create(:ti_perfil_abertura)
      generica, conectividade, prodoc, inativa = create_list(:ti_problema, 4)
      inativa.update!(status: "inativo")
      geral.problemas << [ generica, inativa ]
      escola.problemas << conectividade
      sistemas.problemas << prodoc
      Ti::PerfilUsuario.create!(user: maria, perfil_abertura: escola)

      expect(Ti::Problema.que_pode_abrir(maria)).to contain_exactly(generica, conectividade)
      expect(Ti::Problema.que_pode_abrir(create(:user))).to contain_exactly(generica)
    end
  end
end
