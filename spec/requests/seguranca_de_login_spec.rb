require "rails_helper"

RSpec.describe "Segurança de login" do
  let!(:user) { create(:user, email: "fulano@seed.ap.gov.br", password: "Senha@Forte123") }

  def entrar(senha, lembrar: "0")
    post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: senha, remember_me: lembrar } }
  end

  describe "bloqueio por tentativas" do
    it "avisa quantas tentativas restam a cada erro" do
      entrar("errada")
      expect(flash[:alert]).to eq("E-mail ou senha inválida. Você tem mais 9 tentativas antes de a conta ser bloqueada por 30 minutos.")

      8.times { entrar("errada") }
      expect(flash[:alert]).to eq("E-mail ou senha inválida. Você tem mais 1 tentativa antes de a conta ser bloqueada por 30 minutos.")
    end

    it "bloqueia na décima tentativa e informa o tempo" do
      10.times { entrar("errada") }

      expect(user.reload).to be_access_locked
      expect(flash[:alert]).to eq(
        "Sua conta foi bloqueada após 10 tentativas com senha incorreta. " \
        "Tente novamente em 30 minutos ou procure o administrador do sistema."
      )
    end

    it "não entra com a senha certa enquanto bloqueada, e mostra os minutos que faltam" do
      10.times { entrar("errada") }

      travel 20.minutes do
        entrar("Senha@Forte123")

        expect(flash[:alert]).to match(/Tente novamente em 1[01] minutos/)
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "libera sozinha depois de 30 minutos" do
      10.times { entrar("errada") }

      travel 31.minutes do
        entrar("Senha@Forte123")

        expect(response).to redirect_to(root_path)
        expect(user.reload).to have_attributes(failed_attempts: 0, locked_at: nil)
      end
    end

    it "zera a contagem ao entrar com a senha certa" do
      3.times { entrar("errada") }
      entrar("Senha@Forte123")

      expect(user.reload.failed_attempts).to eq(0)
    end

    it "não revela nada para e-mail inexistente" do
      post user_session_path, params: { user: { email: "ninguem@seed.ap.gov.br", password: "x" } }

      expect(flash[:alert]).to eq("E-mail ou senha inválida.")
    end
  end

  describe "registro de acesso" do
    it "guarda data, contagem e IP do acesso" do
      entrar("Senha@Forte123")

      expect(user.reload).to have_attributes(sign_in_count: 1, current_sign_in_ip: "127.0.0.1")
      expect(user.current_sign_in_at).to be_within(5.seconds).of(Time.current)
    end
  end

  describe "expiração da sessão" do
    it "expira após 8 horas sem uso" do
      entrar("Senha@Forte123")

      travel 7.hours do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      travel 16.hours do
        get root_path # o Devise volta para a página pedida, que então exige login
        follow_redirect!
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq("Sua sessão expirou, por favor, efetue login novamente para continuar.")
      end
    end

    it "não expira para quem marcou Lembrar de mim (até 30 dias)" do
      entrar("Senha@Forte123", lembrar: "1")

      travel 29.days do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "derrubada de sessões" do
    it "sai de todas as sessões quando a versão da sessão muda" do
      entrar("Senha@Forte123", lembrar: "1")
      get root_path
      expect(response).to have_http_status(:ok)

      user.derrubar_sessoes!

      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
