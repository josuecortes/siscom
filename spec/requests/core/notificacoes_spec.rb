require "rails_helper"

RSpec.describe "Minha área: notificações" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:outro) { create(:user) }

  def notificar(user, titulo, **opcoes)
    Core::Notificacoes::Criar.call(destinatarios: user, evento: "core.acesso.papel_concedido", titulo: titulo, ator: nil, **opcoes).first
  end

  it "exige login" do
    get notificacoes_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "com usuário logado" do
    before { sign_in maria }

    it "lista só as próprias notificações, com busca" do
      notificar(maria, "Chamado concluído", mensagem: "Seu chamado foi atendido.")
      notificar(maria, "Novo papel")
      notificar(outro, "Notificação alheia")

      get notificacoes_path
      expect(response.body).to include("Chamado concluído", "Novo papel", "2 notificação(ões) não lida(s)", "2 notificação(ões) listada(s)")
      expect(response.body).not_to include("Notificação alheia")

      get notificacoes_path, params: { q: "atendido" }
      expect(response.body).to include("1 notificação(ões) listada(s)")
    end

    it "mostra o sino com a contagem em todas as páginas" do
      3.times { |n| notificar(maria, "Aviso #{n}") }

      get root_path

      expect(response.body).to include("Abrir notificações (3 não lidas)", "3 não lida(s)", "Aviso 2")
    end

    it "abrir marca como lida e leva para o caminho interno da notificação" do
      notificacao = notificar(maria, "Veja seu perfil", url_acao: "/minha-area/perfil")

      patch abrir_notificacao_path(notificacao)

      expect(response).to redirect_to("/minha-area/perfil")
      expect(notificacao.reload).to be_lida
    end

    it "nunca redireciona para fora do sistema" do
      externas = [ "https://exemplo.com/golpe", "//exemplo.com", "javascript:alert(1)" ].map do |url|
        patch abrir_notificacao_path(notificar(maria, "Link", url_acao: url))
        response.location
      end

      expect(externas).to all(end_with(notificacoes_path))
    end

    it "não abre notificação de outro usuário" do
      alheia = notificar(outro, "Alheia")

      patch abrir_notificacao_path(alheia)

      expect(response).to have_http_status(:not_found)
      expect(alheia.reload).not_to be_lida
    end

    it "marca todas como lidas" do
      2.times { notificar(maria, "Aviso") }
      alheia = notificar(outro, "Alheia")

      patch marcar_todas_notificacoes_path

      expect(response).to redirect_to(notificacoes_path)
      expect(maria.notificacoes.nao_lidas).to be_empty
      expect(alheia.reload).not_to be_lida
    end
  end
end
