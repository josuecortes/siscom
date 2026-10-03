require "rails_helper"

RSpec.describe Core::FontesReferencia do # rubocop:disable RSpec/SpecFilePathFormat
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  describe Core::FontesReferencia::Entidades do
    it "reúne as entidades publicadas pela Api de cada módulo" do
      usuarios = described_class.buscar("core", "usuarios")

      expect(usuarios).to have_attributes(nome: "Administração > Usuários", campo_rotulo: "nome", campos: %w[id nome email],
                                          chave_padrao: "core_usuarios")
      expect(described_class.buscar("core", "nada")).to be_nil
    end
  end

  describe Core::FontesReferencia::Publicar do
    it "publica as fontes padrão, sem duplicar ao rodar de novo" do
      described_class.call
      fonte = described_class.call.find { |f| f.chave == "core_usuarios" }

      expect(Core::FonteReferencia.pluck(:chave)).to contain_exactly("core_usuarios", "rh_pessoas", "rh_unidades", "rh_cargos", "rh_funcoes", "rh_tipos_vinculo")
      expect(fonte).to have_attributes(chave: "core_usuarios", gerenciada_pelo_sistema: true, status: "ativo",
                                       campos_busca: %w[nome email], tipos_de_campo: %w[selecao_unica selecao_multipla])
    end
  end

  describe Core::FontesReferencia::Consultar do
    before do
      Core::FontesReferencia::Publicar.call
      create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
      create(:user, nome: "JOAO SANTOS", email: "joao@seed.ap.gov.br")
      create(:user, nome: "MARIA INATIVA", status: false)
    end

    it "devolve valor, rótulo e subtítulo, em ordem, só dos registros que o módulo dono libera" do
      opcoes = described_class.call(chave: "core_usuarios")

      expect(opcoes.pluck(:rotulo)).to eq([ "JOAO SANTOS", "MARIA OLIVEIRA" ])
      expect(opcoes.last).to include(rotulo: "MARIA OLIVEIRA", subtitulo: "maria@seed.ap.gov.br", valor: be_a(Integer))
    end

    it "busca pelos campos de busca, sem diferenciar maiúsculas, e respeita o limite" do
      expect(described_class.call(chave: "core_usuarios", termo: "joao@").pluck(:rotulo)).to eq([ "JOAO SANTOS" ])
      expect(described_class.call(chave: "core_usuarios", termo: "oliv").pluck(:rotulo)).to eq([ "MARIA OLIVEIRA" ])
      expect(described_class.call(chave: "core_usuarios", limite: 1).size).to eq(1)
    end

    it "trata o termo como texto (sem injeção de SQL nem curingas)" do
      expect(described_class.call(chave: "core_usuarios", termo: "%' OR 1=1 --")).to be_empty
      expect(described_class.call(chave: "core_usuarios", termo: "_")).to be_empty
    end

    it "não devolve nada para fonte inexistente ou inativa" do
      Core::FonteReferencia.find_by!(chave: "core_usuarios").update!(status: "inativo")

      expect(described_class.call(chave: "core_usuarios")).to be_empty
      expect(Core::Api.opcoes_da_fonte("nada")).to be_empty
    end
  end

  describe Core::FontesReferencia::Salvar do
    let(:atributos) do
      { nome: "Usuários por e-mail", entidade_completa: "core:usuarios", campo_rotulo: "email", campo_valor: "id",
        campo_subtitulo: "", campos_busca: [ "email", "" ], tipos_de_campo: [ "selecao_unica" ] }
    end

    it "cria a fonte com a chave gerada do nome e registra na auditoria" do
      resultado = described_class.call(atributos: atributos, salvo_por: superadmin)

      expect(resultado).to be_sucesso
      expect(resultado.objeto).to have_attributes(chave: "usu_rios_por_e_mail", modulo: "core", entidade: "usuarios",
                                                  campo_subtitulo: nil, campos_busca: [ "email" ], gerenciada_pelo_sistema: false)
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "fonte_referencia.criada", ator: superadmin)
    end

    it "recusa campos que não são da entidade, entidade desconhecida e listas vazias" do
      objeto = described_class.call(atributos: atributos.merge(campo_rotulo: "encrypted_password", campos_busca: [], tipos_de_campo: [ "x" ]),
                                    salvo_por: superadmin).objeto
      expect(objeto.errors.attribute_names).to contain_exactly(:campo_rotulo, :campos_busca, :tipos_de_campo)

      desconhecida = described_class.call(atributos: atributos.merge(entidade_completa: "core:senhas"), salvo_por: superadmin)
      expect(desconhecida.objeto.errors[:entidade]).to eq([ "não é uma entidade publicável" ])
    end

    it "em fonte gerenciada pelo sistema só muda nome e descrição" do
      fonte = Core::FontesReferencia::Publicar.call.find { |f| f.chave == "core_usuarios" }

      expect(described_class.call(fonte: fonte, atributos: { nome: "Servidores" }, salvo_por: superadmin)).to be_sucesso
      travada = described_class.call(fonte: fonte.reload, atributos: { campo_rotulo: "email" }, salvo_por: superadmin)
      expect(travada.erros).to eq([ "Esta fonte é gerenciada pelo sistema e não pode ter a estrutura alterada." ])
    end

    it "recusa quem não tem a permissão" do
      resultado = described_class.call(atributos: atributos, salvo_por: create(:user))

      expect(resultado.erros).to eq([ "Você não pode gerenciar fontes de referência." ])
      expect(Core::FonteReferencia.count).to eq(0)
    end
  end
end
