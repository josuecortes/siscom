require "rails_helper"

RSpec.describe "TI: o solicitante edita, cancela e finaliza o chamado" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tecnico) { create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let(:solicitacao) do
    create(:ti_problema, nome: "Sem internet", exige_triagem: false).tap do |problema|
      problema.perfis_abertura << create(:ti_perfil_abertura, padrao: true)
      problema.grupos_tecnicos << create(:ti_grupo_tecnico).tap { |grupo| grupo.vinculos_de_membro.create!(user: tecnico) }
      problema.campos.create!(rotulo: "Sala", obrigatorio: true)
      problema.campos.create!(rotulo: "Foto", tipo: "arquivo", obrigatorio: true)
    end
  end
  let(:foto) { Rack::Test::UploadedFile.new(StringIO.new("imagem"), "image/png", original_filename: "tela.png") }
  let(:chamado) do
    Ti::Chamados::Abrir.call(user: maria, problema_id: solicitacao.id, respostas: { "sala" => "Sala 10", "foto" => foto }).objeto
  end

  def operar(acao, **outros) = Ti::Chamados::Operar.call(chamado: chamado.reload, acao: acao, ator: tecnico, **outros)

  before { sign_in maria }

  describe "editar" do
    it "corrige as respostas do chamado aberto, mantendo o anexo que já foi enviado" do
      get edit_ti_chamado_path(chamado)
      expect(response.body).to include("Editar chamado", 'value="Sala 10"', "Já enviado: tela.png")

      patch ti_chamado_path(chamado), params: { campos: { sala: "Sala 12" } }

      expect(response).to redirect_to(ti_chamado_path(chamado))
      expect(chamado.reload.valores.em_ordem.map { |valor| [ valor.rotulo, valor.valor_texto ] }).to eq([ [ "Sala", "Sala 12" ], [ "Foto", "tela.png" ] ])
      expect(chamado.valores.find_by!(rotulo: "Foto").arquivos.sole.filename.to_s).to eq("tela.png")
      expect(chamado).to have_attributes(status: "aberto", eventos: include(have_attributes(nota: "Solicitante editou os dados do chamado.")))
    end

    it "recusa obrigatório em branco e troca o anexo quando vem outro arquivo" do
      patch ti_chamado_path(chamado), params: { campos: { sala: " " } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Sala deve ser preenchido")

      nova = Rack::Test::UploadedFile.new(StringIO.new("outra"), "image/png", original_filename: "outra.png")
      patch ti_chamado_path(chamado), params: { campos: { sala: "Sala 12", foto: nova } }
      expect(chamado.reload.valores.find_by!(rotulo: "Foto").arquivos.sole.filename.to_s).to eq("outra.png")
    end

    it "quando a TI pediu ajuste, salvar devolve o chamado para quem estava atendendo e avisa" do
      operar("assumir")
      operar("devolver", nota: "Qual é a sala certa?")

      patch ti_chamado_path(chamado), params: { campos: { sala: "Sala 12" } }

      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico)
      expect(chamado.eventos.last.nota).to eq("Solicitante ajustou os dados do chamado e reenviou para a TI.")
      expect(tecnico.notificacoes.last.titulo).to eq("Chamado respondido pelo solicitante")
    end

    it "depois que alguém assumiu, não edita mais" do
      operar("assumir")

      get edit_ti_chamado_path(chamado)
      expect(response).to have_http_status(:forbidden)
      patch ti_chamado_path(chamado), params: { campos: { sala: "Sala 12" } }
      expect(response).to have_http_status(:forbidden)
      expect(chamado.reload.valores.find_by!(rotulo: "Sala").valor_texto).to eq("Sala 10")
    end
  end

  describe "cancelar" do
    it "cancela o chamado aberto com motivo, e ele deixa de contar como em andamento" do
      patch cancelar_ti_chamado_path(chamado), params: { motivo: "" }
      expect(response).to have_http_status(:unprocessable_content)

      patch cancelar_ti_chamado_path(chamado), params: { motivo: "A internet voltou." }

      expect(chamado.reload).to have_attributes(status: "cancelado", em_andamento?: false)
      expect(chamado.eventos.last).to have_attributes(tipo: "cancelado", nota: "Chamado cancelado pelo solicitante: A internet voltou.")
      get ti_chamado_path(chamado)
      expect(response.body).to include("Cancelado")
      expect(response.body).not_to include("Editar chamado")
    end

    it "não cancela o chamado que já está em atendimento" do
      operar("assumir")

      patch cancelar_ti_chamado_path(chamado), params: { motivo: "Desisti." }

      expect(response).to have_http_status(:unprocessable_content)
      expect(chamado.reload.status).to eq("em_atendimento")
    end
  end

  describe "finalizar" do
    before do
      operar("assumir")
      operar("concluir", nota: "Cabo trocado.")
    end

    it "mostra o convite para finalizar e o painel de avaliação" do
      get ti_chamado_path(chamado)
      expect(response.body).to include("O atendimento foi concluído", "Finalizar chamado")

      get finalizacao_ti_chamado_path(chamado)
      expect(response.body).to include("O atendimento resolveu o chamado? *", "Muito bom", "Péssimo")
    end

    it "exige dizer se resolveu, a avaliação e o comentário quando ela é ruim" do
      patch finalizar_ti_chamado_path(chamado), params: { avaliacao: "2", resolvido: "" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Informe se o atendimento resolveu o seu pedido.", "o comentário é obrigatório quando a avaliação é Ruim ou Péssimo")
      expect(chamado.reload.status).to eq("concluido")
    end

    it "finaliza com a avaliação, avisa o técnico e mostra o resultado no chamado" do
      patch finalizar_ti_chamado_path(chamado), params: { resolvido: "sim", avaliacao: "5", comentario: "Rápido!" }

      expect(chamado.reload).to have_attributes(status: "finalizado", avaliacao: 5, avaliacao_resolvido: true, avaliacao_comentario: "Rápido!", finalizado_em: be_present)
      expect(tecnico.notificacoes.last).to have_attributes(titulo: "Chamado finalizado pelo solicitante")
      get ti_chamado_path(chamado)
      expect(response.body).to include("Finalizado", "Muito bom · resolveu o pedido", "Rápido!", "Avaliação: Muito bom.")
    end

    it "outra pessoa não finaliza o chamado" do
      sign_in create(:user)

      patch finalizar_ti_chamado_path(chamado), params: { resolvido: "sim", avaliacao: "5" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
