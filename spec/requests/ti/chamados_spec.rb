require "rails_helper"

RSpec.describe "TI: abrir e acompanhar chamados" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }
  let(:geral) { create(:ti_perfil_abertura, nome: "Geral", padrao: true) }
  let(:rede) { create(:ti_categoria, nome: "Rede") }
  let(:internet) { create(:ti_problema, nome: "Sem internet", categoria: rede, prioridade_padrao: "alta").tap { |p| p.perfis_abertura << geral } }
  let(:restrita) { create(:ti_problema, nome: "Prodoc - Cadastro").tap { |p| p.perfis_abertura << create(:ti_perfil_abertura, nome: "Sistemas") } }

  def abrir(solicitacao, campos: {}, **chamado)
    post ti_chamados_path, params: { chamado: { problema_id: solicitacao.id }.merge(chamado), campos: campos }
  end

  def lotar(user, unidade)
    pessoa = create(:rh_pessoa, user: user, email: user.email, nome: user.nome)
    create(:rh_lotacao, pessoa: pessoa, unidade: unidade, funcao: create(:rh_funcao, nome: "Técnico"))
  end

  before do
    Rh::Tabelas.garantir_padroes
    sign_in maria
  end

  it "exige login" do
    sign_out maria

    get ti_chamados_path

    expect(response).to redirect_to(new_user_session_path)
  end

  describe "abertura" do
    it "abre o chamado com código, prioridade da solicitação, retrato do solicitante e o evento" do
      abrir(internet)

      chamado = Ti::Chamado.sole
      expect(response).to redirect_to(ti_chamados_path)
      expect(chamado).to have_attributes(codigo: format("TI-%06d", chamado.id), status: "aberto", prioridade: "alta", solicitante: maria,
                                         solicitante_nome: "MARIA OLIVEIRA", solicitante_email: "maria@seed.ap.gov.br", rh_unidade_id: nil)
      expect(chamado.eventos.sole).to have_attributes(tipo: "aberto", para_status: "aberto", ator: maria)
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "chamado.aberto", modulo: "ti")
    end

    it "não abre solicitação fora dos perfis do usuário, inativa ou inexistente" do
      internet.update!(status: "inativo")

      [ restrita, internet, Struct.new(:id).new(0) ].each { |solicitacao| abrir(solicitacao) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Solicitação deve ser escolhida na lista")
      expect(Ti::Chamado.count).to eq(0)
    end

    it "passa a abrir a solicitação restrita quando ganha o perfil de abertura" do
      Ti::PerfilUsuario.create!(user: maria, perfil_abertura: restrita.perfis_abertura.sole)

      abrir(restrita)

      expect(Ti::Chamado.sole.problema).to eq(restrita)
    end

    it "bloqueia um segundo chamado em andamento da mesma solicitação, salvo quando ela permite vários" do
      abrir(internet)
      abrir(internet)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Você já tem um chamado em andamento para esta solicitação")

      Ti::Chamado.sole.update!(status: "finalizado")
      abrir(internet)
      internet.update!(permite_varios_abertos: true)
      abrir(internet)

      expect(Ti::Chamado.count).to eq(3)
    end

    it "com uma lotação, guarda a unidade e a função; com duas, exige escolher" do
      nuinfo = create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
      primeira = lotar(maria, nuinfo)
      abrir(internet)
      expect(Ti::Chamado.sole).to have_attributes(rh_unidade_id: nuinfo.id, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", funcao_nome: "TÉCNICO")

      internet.update!(permite_varios_abertos: true)
      escola = create(:rh_unidade, nome: "Escola A", sigla: "EEA")
      segunda = create(:rh_lotacao, pessoa: primeira.pessoa, unidade: escola, funcao: primeira.funcao)
      abrir(internet)
      expect(response.body).to include("Unidade deve ser escolhida")

      abrir(internet, lotacao_id: segunda.id)
      expect(Ti::Chamado.recentes.first).to have_attributes(rh_unidade_id: escola.id, unidade_nome: "EEA - ESCOLA A")
    end

    it "avisa os membros dos grupos técnicos da solicitação, menos quem abriu" do
      grupo = create(:ti_grupo_tecnico, nome: "Redes")
      internet.grupos_tecnicos << grupo
      tecnico = create(:user)
      [ tecnico, maria ].each { |user| grupo.vinculos_de_membro.create!(user: user) }
      de_fora = create(:user).tap { |u| create(:ti_grupo_tecnico).vinculos_de_membro.create!(user: u) }

      abrir(internet)

      expect(tecnico.notificacoes.sole).to have_attributes(titulo: "Novo chamado aberto", mensagem: "#{Ti::Chamado.sole.codigo} - SEM INTERNET")
      expect(maria.notificacoes.count + de_fora.notificacoes.count).to eq(0)
    end
  end

  describe "formulário da solicitação" do
    before do
      Core::Api.publicar_fontes_padrao
      { "Nome completo" => { obrigatorio: true }, "CPF" => { mascara: "cpf" }, "Nascimento" => { tipo: "data" },
        "Perfil" => { tipo: "selecao", opcoes: "Responsável\nAuxiliar" }, "Sistemas" => { tipo: "selecao_multipla", opcoes: "Prodoc\nSigdoc\nSiscom" },
        "Urgente" => { tipo: "sim_nao" }, "Quantidade" => { tipo: "numero" }, "Unidade" => { tipo: "busca", fonte: "rh_unidades" },
        "Carta" => { tipo: "arquivo" }, "Observações" => { tipo: "texto_longo" } }.each do |rotulo, atributos|
        internet.campos.new(tipo: atributos.fetch(:tipo, "texto")).update!(atributos.merge(rotulo: rotulo))
      end
    end

    it "mostra os campos da solicitação escolhida, cada um no seu tipo" do
      get new_ti_chamado_path, params: { problema_id: internet.id }

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Abrir chamado", "Nome completo *", "SEM INTERNET")
      expect(
        cpf: html.at_css("#campo_cpf")["data-mascara-tipo-value"], nascimento: html.at_css("#campo_nascimento")["data-mascara-tipo-value"],
        perfil: html.css("select#campo_perfil option").map(&:text), sistemas: html.css("input[type=checkbox][name='campos[sistemas][]']").size,
        urgente: html.css("input[type=radio][name='campos[urgente]']").map { |campo| campo["value"] },
        unidade: html.at_css("[data-controller='autocomplete']")["data-autocomplete-url-value"],
        carta: html.css("input[type=file]#campo_carta").size, observacoes: html.css("textarea#campo_observacoes").size
      ).to eq(
        cpf: "cpf", nascimento: "data", perfil: %w[Selecione Responsável Auxiliar], sistemas: 3, urgente: %w[sim nao],
        unidade: ti_opcoes_do_campo_path(internet.campos.find_by!(chave: "unidade")), carta: 1, observacoes: 1
      )
    end

    it "guarda as respostas com o nome do campo e mostra na página do chamado" do
      nuinfo = create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
      carta = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 carta"), "application/pdf", original_filename: "carta.pdf")

      abrir(internet, campos: { nome_completo: " Ana Paula ", cpf: "529.982.247-25", nascimento: "15/01/1985", perfil: "Auxiliar", sistemas: [ "", "Prodoc", "Siscom" ],
                                urgente: "sim", quantidade: "2", unidade: nuinfo.id, carta: carta, observacoes: "Linha 1\nLinha 2" })

      chamado = Ti::Chamado.sole
      expect(chamado.valores.em_ordem.pluck(:rotulo, :valor_texto)).to eq(
        [ [ "Nome completo", "Ana Paula" ], [ "CPF", "529.982.247-25" ], [ "Nascimento", "15/01/1985" ], [ "Perfil", "Auxiliar" ], [ "Sistemas", "Prodoc, Siscom" ],
          [ "Urgente", "Sim" ], [ "Quantidade", "2" ], [ "Unidade", "NÚCLEO DE INFORMÁTICA" ], [ "Carta", "carta.pdf" ], [ "Observações", "Linha 1\nLinha 2" ] ]
      )
      expect(chamado.valores.find_by!(rotulo: "Unidade").valor_json).to eq("valor" => nuinfo.id, "rotulo" => "NÚCLEO DE INFORMÁTICA")
      expect(chamado.valores.find_by!(rotulo: "Carta").arquivos.sole.filename.to_s).to eq("carta.pdf")

      get ti_chamado_path(chamado)
      expect(response.body).to include("Chamado #{chamado.codigo}", "SEM INTERNET", "Ana Paula", "Prodoc, Siscom", "carta.pdf", "Chamado aberto pelo solicitante.")
    end

    it "recusa obrigatório em branco e valores que não batem com o tipo, mantendo o que foi digitado" do
      abrir(internet, campos: { nome_completo: " ", cpf: "529", nascimento: "31/02/2020", perfil: "Outro", sistemas: [ "Prodoc", "Zap" ], urgente: "talvez",
                                quantidade: "dois", unidade: "9999999" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome completo deve ser preenchido", "Nascimento deve ser uma data válida", "Perfil deve ser uma das opções",
                                       "Sistemas deve ter só opções da lista", "Urgente deve ser Sim ou Não", "Quantidade deve ser um número",
                                       "Unidade deve ser escolhido na lista", 'value="529"')
      expect(Ti::Chamado.count).to eq(0)
    end

    it "responde as opções do campo de busca só para quem pode abrir a solicitação" do
      create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
      campo = internet.campos.find_by!(chave: "unidade")

      get ti_opcoes_do_campo_path(campo), params: { q: "inform" }
      expect(response.parsed_body).to include("todas" => false, "opcoes" => [ hash_including("rotulo" => "NÚCLEO DE INFORMÁTICA", "subtitulo" => "NUINFO") ])

      get ti_opcoes_do_campo_path(campo), params: { q: "zzz" }
      expect(response.parsed_body["todas"]).to be(true)

      internet.vinculos_de_perfil.destroy_all
      get ti_opcoes_do_campo_path(campo)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "meus chamados" do
    it "lista só os chamados do usuário, com busca e filtro de situação" do
      abrir(internet)
      meu = Ti::Chamado.sole
      outro = create(:user)
      Ti::Chamado.create!(problema: internet, solicitante: outro, solicitante_nome: outro.nome, solicitante_email: outro.email, aberto_em: Time.current)

      get ti_chamados_path
      expect(response.body).to include("1 chamado(s) encontrado(s)", meu.codigo, "SEM INTERNET", "Aberto")

      get ti_chamados_path, params: { status: "encerrados" }
      expect(response.body).to include("0 chamado(s) encontrado(s)")

      get ti_chamados_path, params: { q: "internet", status: "andamento" }
      expect(response.body).to include("1 chamado(s) encontrado(s)")
    end

    it "não mostra o chamado de outra pessoa" do
      outro = create(:user)
      alheio = Ti::Chamado.create!(problema: internet, solicitante: outro, solicitante_nome: outro.nome, solicitante_email: outro.email, aberto_em: Time.current)

      get ti_chamado_path(alheio)

      expect(response).to have_http_status(:not_found)
    end
  end
end
