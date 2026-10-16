require "rails_helper"

RSpec.describe "TI: campos da solicitação" do
  let(:supervisor) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") } }
  let(:tecnico) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let(:solicitacao) { create(:ti_problema, nome: "Prodoc - Cadastro") }

  def criar(**campo) = post(ti_solicitacao_campos_path(solicitacao), params: { campo: campo })

  it "técnico não mexe nos campos" do
    campo = create(:ti_campo_problema, problema: solicitacao)
    sign_in tecnico

    respostas = [ -> { get ti_solicitacao_campos_path(solicitacao) }, -> { criar(rotulo: "X") },
                  -> { patch desativar_ti_solicitacao_campo_path(solicitacao, campo) } ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com supervisor" do
    before { sign_in supervisor }

    it "cria campos em ordem, com a chave gerada do nome" do
      criar(rotulo: "Nome completo", tipo: "texto", obrigatorio: "1", exemplo: "Ex.: Maria Oliveira")
      criar(rotulo: "CPF", tipo: "texto", mascara: "cpf")
      criar(rotulo: "Nome completo", tipo: "texto_longo", mascara: "cpf")

      expect(response).to redirect_to(ti_solicitacao_campos_path(solicitacao))
      expect(solicitacao.campos.ordenados.pluck(:chave, :posicao, :tipo, :mascara, :obrigatorio))
        .to eq([ [ "nome_completo", 1, "texto", nil, true ], [ "cpf", 2, "texto", "cpf", false ], [ "nome_completo_2", 3, "texto_longo", nil, false ] ])
      expect(Core::RegistroAuditoria.where(evento: "campo.criado").count).to eq(3)
    end

    it "campo de seleção guarda as opções, uma por linha, e exige ao menos uma" do
      criar(rotulo: "Perfil", tipo: "selecao", opcoes: "")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Opções deve ter ao menos uma opção")

      criar(rotulo: "Perfil", tipo: "selecao", opcoes: "Responsável por unidade\n  Auxiliar \n\nAuxiliar\nConsulta")
      expect(solicitacao.campos.sole.opcoes).to eq([ "Responsável por unidade", "Auxiliar", "Consulta" ])
    end

    it "campo de busca exige uma fonte de referência publicada" do
      criar(rotulo: "Unidade", tipo: "busca", fonte: "inexistente")
      expect(response.body).to include("Fonte de dados não é uma fonte publicada")

      criar(rotulo: "Unidade", tipo: "busca", fonte: "rh_unidades")
      expect(solicitacao.campos.sole).to have_attributes(tipo: "busca", fonte: "rh_unidades", opcoes: [])
    end

    it "edita sem mudar a chave, muda a ordem e o status" do
      campo = create(:ti_campo_problema, problema: solicitacao, rotulo: "Nome")
      create(:ti_campo_problema, problema: solicitacao, rotulo: "E-mail")

      patch ti_solicitacao_campo_path(solicitacao, campo), params: { campo: { rotulo: "Nome completo", posicao: 5, tipo: "selecao_unica", opcoes: "Sim\nNão" } }
      patch desativar_ti_solicitacao_campo_path(solicitacao, campo)

      expect(campo.reload).to have_attributes(chave: "nome", rotulo: "Nome completo", posicao: 5, tipo: "selecao_unica", status: "inativo")
      get ti_solicitacao_campos_path(solicitacao)
      expect(response.body).to include("Campos do chamado PRODOC - CADASTRO", "2 campo(s) registrado(s)", "Seleção única (botões)", "Sim, Não", "Inativo")
      expect(response.body.index("E-mail")).to be < response.body.index("Nome completo")
    end

    it "mostra no painel os tipos, as máscaras e as fontes" do
      get new_ti_solicitacao_campo_path(solicitacao)

      expect(response.body).to include("Novo campo", "Texto longo", "Múltiplos arquivos", "Busca (várias opções)", "Telefone fixo", "Selecione uma fonte publicada")
    end
  end
end
