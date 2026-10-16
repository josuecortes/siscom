require "rails_helper"

# O cenário precisa de vários papéis ao mesmo tempo (solicitante, técnico, triador, supervisor).
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Ti::Chamados::Operar do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: papel) }

  let(:redes) { create(:ti_grupo_tecnico, nome: "Redes") }
  let(:solicitacao) { create(:ti_problema, nome: "Sem internet", exige_triagem: false).tap { |p| p.grupos_tecnicos << redes } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tecnico) { com_papel("tecnico", "JOAO TECNICO").tap { |u| redes.vinculos_de_membro.create!(user: u) } }
  let(:triador) { com_papel("triagem", "ANA TRIADORA").tap { |u| redes.vinculos_de_membro.create!(user: u) } }
  let(:supervisor) { com_papel("supervisor", "SUPERVISOR") }
  let(:chamado) do
    Ti::Chamado.create!(problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)
  end

  def fazer(acao, ator, **outros) = Ti::Chamados::Operar.call(chamado: chamado.reload, acao: acao, ator: ator, **outros)
  def acoes(ator) = Ti::Chamados::Operar.disponiveis(chamado.reload, ator).map(&:chave)

  describe "quem vê o chamado" do
    it "membro do grupo técnico da solicitação e supervisão veem; os outros não" do
      de_fora = com_papel("tecnico", "TECNICO DE OUTRO GRUPO")
      chamado

      expect([ tecnico, triador, supervisor, de_fora, maria ].map { |user| Ti::Chamados::Acesso.visiveis(user).exists?(id: chamado.id) })
        .to eq([ true, true, true, false, false ])
      expect(fazer("assumir", de_fora)).to be_falha
    end
  end

  describe "solicitação sem triagem" do
    it "o técnico assume, o chamado entra em atendimento e o solicitante é avisado" do
      expect(acoes(tecnico)).to eq(%w[assumir])

      fazer("assumir", tecnico)

      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico)
      expect(chamado.eventos.last).to have_attributes(tipo: "assumido", de_status: "aberto", para_status: "em_atendimento",
                                                      nota: "Chamado assumido para atendimento por JOAO TECNICO.")
      expect(maria.notificacoes.sole.titulo).to eq("Chamado em atendimento")
      expect(acoes(tecnico)).to eq(%w[devolver impedir concluir liberar prioridade])
    end

    it "outro técnico não toma o chamado que já tem responsável; a supervisão sim" do
      outro = com_papel("tecnico", "PEDRO TECNICO").tap { |u| redes.vinculos_de_membro.create!(user: u) }
      fazer("assumir", tecnico)

      expect(fazer("assumir", outro)).to be_falha
      expect(fazer("concluir", outro, nota: "Feito")).to be_falha
      expect(fazer("assumir", supervisor)).to be_sucesso
      expect(chamado.reload.responsavel).to eq(supervisor)
    end

    it "grupo que não deixa os membros pegarem chamados: só a supervisão atribui" do
      redes.update!(permite_autoatribuicao: false)

      expect(fazer("assumir", tecnico)).to be_falha
      expect(fazer("atribuir", supervisor, alvo: maria, nota: "Vai você")).to be_falha
      expect(fazer("atribuir", supervisor, alvo: tecnico, nota: "Você conhece a sala.")).to be_sucesso
      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico)
      expect(tecnico.notificacoes.sole.titulo).to eq("Chamado atribuído a você")
    end

    it "impede, pede ajuste e conclui, sempre com anotação" do
      fazer("assumir", tecnico)

      expect(fazer("impedir", tecnico)).to be_falha
      fazer("impedir", tecnico, nota: "Aguardando peça.")
      expect(chamado.reload).to have_attributes(status: "impedido", nota_triagem: "Aguardando peça.")
      fazer("devolver", tecnico, nota: "Qual é a sala?")
      expect(chamado.reload.status).to eq("aguardando_solicitante")
      fazer("concluir", tecnico, nota: "Cabo trocado.")
      expect(chamado.reload).to have_attributes(status: "concluido", concluido_em: be_present)
    end

    it "só a supervisão reabre o chamado concluído, e o solicitante é avisado de cada etapa" do
      fazer("assumir", tecnico)
      fazer("concluir", tecnico, nota: "Cabo trocado.")

      expect(fazer("reabrir", tecnico, nota: "x")).to be_falha
      fazer("reabrir", supervisor, nota: "Voltou a cair.")

      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico, concluido_em: nil)
      expect(maria.notificacoes.order(:id).pluck(:titulo)).to eq([ "Chamado em atendimento", "Chamado concluído", "Chamado reaberto" ])
    end

    it "liberar deixa o chamado sem responsável e avisa os técnicos do grupo" do
      outro = com_papel("tecnico", "PEDRO TECNICO").tap { |u| redes.vinculos_de_membro.create!(user: u) }
      fazer("assumir", tecnico)

      fazer("liberar", tecnico, nota: "Saio de férias.")

      expect(chamado.reload).to have_attributes(status: "aguardando_tecnico", responsavel: nil)
      expect(outro.notificacoes.sole.titulo).to eq("Chamado aguardando atendimento")
      expect(acoes(outro)).to include("assumir")
    end

    it "muda a prioridade com motivo e registra de qual para qual" do
      fazer("assumir", tecnico)

      expect(fazer("prioridade", tecnico, prioridade: "normal", nota: "x")).to be_falha
      fazer("prioridade", tecnico, prioridade: "urgente", nota: "Diretoria parada.")

      expect(chamado.reload.prioridade).to eq("urgente")
      expect(chamado.eventos.last.nota).to eq("Prioridade alterada de Normal para Urgente: Diretoria parada.")
    end
  end

  describe "solicitação com triagem" do
    before { solicitacao.update!(exige_triagem: true) }

    it "o triador assume para triagem e encaminha para o técnico, que então assume" do
      fazer("assumir", triador)
      expect(chamado.reload).to have_attributes(status: "em_triagem", triador: triador, responsavel: nil)
      tecnico

      fazer("encaminhar", triador, nota: "Problema no switch do bloco B.")
      expect(chamado.reload).to have_attributes(status: "aguardando_tecnico", nota_triagem: "Problema no switch do bloco B.")
      expect(tecnico.notificacoes.sole.titulo).to eq("Chamado aguardando atendimento")

      fazer("assumir", tecnico)
      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico, triador: triador)
    end

    it "o técnico pode pegar direto, e o histórico registra que a triagem foi pulada" do
      fazer("assumir", tecnico)

      expect(chamado.reload.status).to eq("em_atendimento")
      expect(chamado.eventos.last.nota).to end_with("A etapa de triagem foi pulada.")
    end

    it "o triador não conclui nem atende" do
      fazer("assumir", triador)

      expect(acoes(triador)).to eq(%w[encaminhar devolver liberar prioridade])
      expect(fazer("concluir", triador, nota: "x")).to be_falha
    end
  end

  describe Ti::Chamados::Responder do
    it "o solicitante responde ao pedido de ajuste e o chamado volta para o responsável" do
      fazer("assumir", tecnico)
      fazer("devolver", tecnico, nota: "Qual é a sala?")

      expect(described_class.call(chamado: chamado.reload, user: tecnico, nota: "x")).to be_falha
      expect(described_class.call(chamado: chamado, user: maria, nota: " ")).to be_falha
      resultado = described_class.call(chamado: chamado, user: maria, nota: "Sala 12.")

      expect(resultado).to be_sucesso
      expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico)
      expect(chamado.eventos.last).to have_attributes(tipo: "respondido", nota: "Solicitante respondeu: Sala 12.")
    end
  end

  it "registra na auditoria cada ação" do
    fazer("assumir", tecnico)
    fazer("concluir", tecnico, nota: "Feito.")

    expect(Core::RegistroAuditoria.where(modulo: "ti").order(:id).pluck(:evento)).to eq(%w[chamado.assumido chamado.concluido])
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
