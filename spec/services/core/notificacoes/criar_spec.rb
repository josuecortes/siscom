require "rails_helper"

RSpec.describe Core::Notificacoes::Criar do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { create(:user) }
  let(:admin) { create(:user, nome: "ADMIN DA SILVA") }

  before { allow(Turbo::StreamsChannel).to receive_messages(broadcast_replace_to: nil, broadcast_append_to: nil) }

  def criar(**opcoes)
    described_class.call(destinatarios: [ maria, joao ], evento: "core.acesso.papel_concedido", titulo: "Novo papel",
                         mensagem: "Detalhe", **opcoes)
  end

  it "cria uma notificação para cada destinatário" do
    notificacoes = criar(ator: admin, url_acao: "/minha-area/perfil", alvo: maria)

    expect(notificacoes.map(&:user)).to contain_exactly(maria, joao)
    expect(maria.notificacoes.sole).to have_attributes(
      modulo: "core", evento: "acesso.papel_concedido", titulo: "Novo papel", mensagem: "Detalhe", ator: admin,
      url_acao: "/minha-area/perfil", alvo_tipo: "User", alvo_id: maria.id, lida_em: nil
    )
  end

  it "não notifica quem fez a ação nem usuário desativado" do
    joao.update!(status: false)

    expect(criar(ator: maria)).to be_empty
  end

  it "usa o ator do contexto quando não informado" do
    Core::Contexto.set(ator: admin) { criar }

    expect(maria.notificacoes.sole.nome_do_ator).to eq("ADMIN DA SILVA")
    expect(maria.notificacoes.sole.nome_do_modulo).to eq("Administração")
  end

  it "atualiza o sino e mostra o aviso flutuante em tempo real" do
    criar(destinatarios: maria, ator: nil)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
      .with([ maria, :notificacoes ], hash_including(target: "sino_notificacoes"))
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with([ maria, :notificacoes ], hash_including(target: "avisos", locals: { tipo: :notice, mensagem: "Novo papel" }))
  end

  it "marca uma ou todas como lidas" do
    primeira, segunda = Array.new(2) { criar(destinatarios: maria, ator: nil).first }

    Core::Notificacoes::MarcarLidas.uma(primeira)
    expect(maria.notificacoes.nao_lidas).to contain_exactly(segunda)

    expect(Core::Notificacoes::MarcarLidas.todas(maria)).to eq(1)
    expect(Core::Notificacoes::MarcarLidas.todas(maria)).to eq(0)
    expect(maria.notificacoes.nao_lidas).to be_empty
  end

  it "conceder um papel avisa o usuário, mas a importação pelo sistema não" do
    superadmin = create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") }

    Core::Acessos::Conceder.call(user: maria, modulo: "core", papel: "auditor", concedido_por: superadmin)
    Core::Acessos::Conceder.call(user: joao, modulo: "core", papel: "auditor", pelo_sistema: true)

    expect(maria.notificacoes.sole).to have_attributes(titulo: "Você recebeu um novo papel",
                                                       mensagem: "Papel Auditor no módulo Administração. O menu já mostra o que mudou.")
    expect(joao.notificacoes).to be_empty
  end
end
