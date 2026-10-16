require "rails_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe "Equipamentos: lista, cadastro e edição" do
  let(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let(:asjur) { create(:rh_unidade, nome: "Assessoria Jurídica", sigla: "ASJUR") }
  let(:gestor) { usuario_de_equipamentos("GESTOR DO NUINFO", unidade: nuinfo, papel: "gestor") }
  let(:admin) { usuario_de_equipamentos("ADMIN DE EQUIPAMENTOS", papel: "admin") }
  let!(:monitor) { create(:equipamentos_item, unidade: nuinfo, numero_patrimonio: "PAT001", contrato: "012/2025") }
  let!(:da_asjur) { create(:equipamentos_item, unidade: asjur, tipo_equipamento: "Notebook", marca: "LENOVO", modelo: "T14", numero_patrimonio: "PAT900") }
  let(:dados) { { tipo_equipamento: "Impressora", marca: "hp", modelo: "LaserJet 1020", numero_serial: "sn-123", garantia: "12" } }

  def nomes = Nokogiri::HTML(response.body).css("tbody tr[id] td:first-child a").map { |link| link.text.strip }
  def acoes(item) = Nokogiri::HTML(response.body).css("tr##{ActionView::RecordIdentifier.dom_id(item)} td:last-child [title]").pluck("title")

  it "quem não é administrador nem gestor não vê a lista (só recebe equipamentos, pela Minha área)" do
    sign_in usuario_de_equipamentos("MARIA OLIVEIRA", unidade: nuinfo)

    respostas = [ -> { get equipamentos_itens_path }, -> { get new_equipamentos_item_path }, -> { get equipamentos_recebimentos_path } ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to eq([ 403, 403, 200 ])
  end

  context "com o gestor da unidade" do
    before { sign_in gestor }

    it "vê só os equipamentos das unidades em que está lotado, com as ações na linha" do
      get equipamentos_itens_path

      expect(nomes).to eq([ "Monitor DELL P2419H" ])
      expect(response.body).to include("1 equipamento(s) em uso", "NUINFO - NÚCLEO DE INFORMÁTICA", "PAT001", "Exportar Excel", "Novo equipamento")
      expect(acoes(monitor)).to eq([ "Visualizar equipamento", "Editar equipamento", "Kit", "Mudar situação", "Movimentar para outra unidade", "Emprestar ou cautelar" ])
      get equipamentos_item_path(da_asjur), headers: { "Turbo-Frame" => "painel" }
      expect(response).to have_http_status(:not_found)
    end

    it "cadastra na própria unidade, em maiúsculas, e o cadastro entra no histórico" do
      get new_equipamentos_item_path
      expect(response.body).to include("Cadastrar equipamento", "Um kit (várias peças)", 'value="NUINFO - NÚCLEO DE INFORMÁTICA"', "Peças do kit")

      post equipamentos_itens_path, params: { modo: "individual", item: dados.merge(rh_unidade_id: nuinfo.id) }

      item = Equipamentos::Item.find_by!(numero_serial: "SN-123")
      expect(response).to redirect_to(equipamentos_itens_path)
      expect(item).to have_attributes(marca: "HP", modelo: "LASERJET 1020", garantia: 12, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", cadastrado_por: gestor, status: "ativo")
      expect(item.eventos.sole).to have_attributes(tipo: "cadastrado", ator_nome: "GESTOR DO NUINFO")
    end

    it "não cadastra em unidade alheia, sem identificador, com serial repetido, nem switch sem MAC" do
      tentar = lambda do |atributos|
        post equipamentos_itens_path, params: { modo: "individual", item: dados.merge(rh_unidade_id: nuinfo.id).merge(atributos) }
        [ response.status, Nokogiri::HTML(response.body).css("[data-faixa-aviso='erro'], p[id^='erro_']").map { |erro| erro.text.squish }.join(" | ") ]
      end

      expect(tentar.call(rh_unidade_id: asjur.id).last).to include("Você não pode cadastrar equipamentos nesta unidade.")
      expect(tentar.call(numero_serial: "")).to eq([ 422, "Preencha pelo menos um identificador: número serial, patrimônio ou outra identificação." ])
      expect(tentar.call(numero_patrimonio: "pat001").last).to include("já está em outro equipamento")
      expect(tentar.call(tipo_equipamento: "Switch").last).to include("Mac não pode ficar em branco").or include("MAC não pode ficar em branco")
      expect(Equipamentos::Item.count).to eq(2)
    end

    it "cadastra um kit: todas as peças com o mesmo código, ou nenhuma" do
      pecas = { "0" => { tipo_equipamento: "Gabinete", marca: "Dell", modelo: "Optiplex", numero_patrimonio: "PAT010" },
                "1" => { tipo_equipamento: "Monitor", marca: "Dell", modelo: "P2419H", numero_serial: "SN-M1" }, "2" => { tipo_equipamento: "", marca: "" } }
      kit = { identificacao_kit: "Laboratório 2, mesa 5", rh_unidade_id: nuinfo.id, contrato: "012/2025" }

      post equipamentos_itens_path, params: { modo: "kit", kit: kit, pecas: pecas.merge("1" => pecas["1"].merge(numero_serial: "")) }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Revise as peças destacadas.", "Preencha pelo menos um identificador", 'value="Laboratório 2, mesa 5"')
      expect(Equipamentos::Item.count).to eq(2)

      post equipamentos_itens_path, params: { modo: "kit", kit: kit, pecas: pecas }
      novas = Equipamentos::Item.where(identificacao_kit: "LABORATÓRIO 2, MESA 5")
      expect(novas.pluck(:tipo_equipamento, :contrato)).to contain_exactly([ "Gabinete", "012/2025" ], [ "Monitor", "012/2025" ])
      expect(novas.pluck(:codigo_kit).uniq).to match([ /\AKIT-\d{6}\z/ ])
    end

    it "a edição fica registrada: quem mudou e o que mudou, no histórico do equipamento e na auditoria" do
      get edit_equipamentos_item_path(monitor)
      expect(response.body).to include("A unidade só muda por movimentação", 'value="DELL"')

      patch equipamentos_item_path(monitor), params: { item: { marca: "LG", modelo: "P2419H", numero_patrimonio: "PAT001", localizacao_fisica: "Sala 3", rh_unidade_id: asjur.id } }

      evento = monitor.eventos.em_ordem.last
      expect(monitor.reload).to have_attributes(marca: "LG", localizacao_fisica: "Sala 3", rh_unidade_id: nuinfo.id) # a unidade não muda pela edição
      expect(evento).to have_attributes(tipo: "editado", ator: gestor, nota: "Marca: DELL → LG; Localização física: vazio → Sala 3",
                                        mudancas: { "marca" => %w[DELL LG], "localizacao_fisica" => [ nil, "Sala 3" ] })
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "item.editado", ator: gestor)
    end

    it "muda a situação com motivo; descartado sai da lista do dia a dia e não pode ser movimentado" do
      patch mudar_situacao_equipamentos_item_path(monitor), params: { status: "descartado", motivo: " " }
      expect(response.body).to include("Motivo deve ser preenchido.")

      patch mudar_situacao_equipamentos_item_path(monitor), params: { status: "descartado", motivo: "Tela quebrada, sem conserto." }
      expect(monitor.reload.status).to eq("descartado")
      expect(monitor.eventos.em_ordem.last.nota).to eq("De Ativo para Descartado. Motivo: Tela quebrada, sem conserto.")

      get equipamentos_itens_path
      padrao = nomes
      get equipamentos_itens_path, params: { status: "descartado" }
      expect([ padrao, nomes, acoes(monitor) ]).to eq([ [], [ "Monitor DELL P2419H" ], [ "Visualizar equipamento", "Editar equipamento", "Kit", "Mudar situação" ] ])
    end

    it "inclui uma peça num kit da mesma unidade pelo código e tira do kit" do
      create(:equipamentos_item, unidade: nuinfo, codigo_kit: "KIT-000007", identificacao_kit: "LAB 1")
      create(:equipamentos_item, unidade: asjur, codigo_kit: "KIT-000008", identificacao_kit: "JURIDICO")

      get kit_equipamentos_itens_path, params: { codigo_kit: "kit-000007" }
      expect(response.parsed_body).to include("identificacao" => "LAB 1", "pecas" => 1)
      patch entrar_no_kit_equipamentos_item_path(monitor), params: { codigo_kit: "KIT-000008" }
      expect(response.body).to include("é de outra unidade")
      patch entrar_no_kit_equipamentos_item_path(monitor), params: { codigo_kit: "kit-000007" }
      expect(monitor.reload).to have_attributes(codigo_kit: "KIT-000007", identificacao_kit: "LAB 1")

      patch sair_do_kit_equipamentos_item_path(monitor)
      expect(monitor.reload.codigo_kit).to be_nil
      expect(monitor.eventos.em_ordem.pluck(:tipo)).to eq(%w[kit_alterado kit_alterado])
    end

    it "ver abre no painel, só para leitura, com o histórico" do
      get equipamentos_item_path(monitor), headers: { "Turbo-Frame" => "painel" }

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Monitor DELL P2419H", "PAT001", "Histórico", "012/2025")
      expect(html.css("[role='dialog'] a, [role='dialog'] button").map { |item| item.text.strip }).to eq([ "×", "Fechar" ])
    end
  end

  context "com o administrador" do
    before { sign_in admin }

    it "vê todas as unidades, filtra e exporta o Excel com os mesmos filtros" do
      get equipamentos_itens_path
      todos = nomes
      filtrar = ->(filtros) { get(equipamentos_itens_path, params: filtros) && nomes }

      expect(todos).to contain_exactly("Monitor DELL P2419H", "Notebook LENOVO T14")
      expect([ filtrar.call(q: "lenovo"), filtrar.call(tipo_equipamento: "Monitor"), filtrar.call(unidade_id: asjur.id), filtrar.call(contrato: "012"), filtrar.call(situacao: "emprestado"),
               filtrar.call(q: "pat9") ])
        .to eq([ [ "Notebook LENOVO T14" ], [ "Monitor DELL P2419H" ], [ "Notebook LENOVO T14" ], [ "Monitor DELL P2419H" ], [], [ "Notebook LENOVO T14" ] ])

      get equipamentos_itens_path(format: :xlsx, tipo_equipamento: "Monitor")
      expect([ response.media_type, response.body[0, 2] ]).to eq([ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "PK" ])
    end

    it "cadastra em qualquer unidade, escolhida por busca" do
      get new_equipamentos_item_path
      expect(Nokogiri::HTML(response.body).at_css("[data-controller='autocomplete']")["data-autocomplete-url-value"]).to eq("/equipamentos/opcoes/unidades")

      post equipamentos_itens_path, params: { modo: "individual", item: dados.merge(rh_unidade_id: asjur.id) }
      expect(Equipamentos::Item.find_by!(numero_serial: "SN-123").unidade_nome).to eq("ASJUR - ASSESSORIA JURÍDICA")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
