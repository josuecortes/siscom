# Login dos system specs. O `sign_in` do Devise vale só para a PRÓXIMA requisição que chega ao
# servidor; com navegador de verdade, uma requisição atrasada do exemplo anterior (refresh do Turbo,
# busca de autocomplete) podia gastar esse login e o exemplo caía na tela de entrada, de vez em quando.
# Aqui o usuário fica valendo durante o exemplo inteiro: qualquer requisição sem ele é autenticada.
# Sair pelo sistema (DELETE /users/sign_out) desliga, para os specs de logout continuarem valendo.
# Com `using_session` (dois navegadores no mesmo exemplo), cada sessão do Capybara guarda o seu usuário.
module LoginDeSistema
  mattr_accessor :usuarios, default: {} # nome da sessão do Capybara => usuário
  mattr_accessor :ultimo

  def self.limpar
    self.usuarios = {}
    self.ultimo = nil
  end

  def sign_in(user, **)
    LoginDeSistema.usuarios[Capybara.session_name] = user
    LoginDeSistema.ultimo = user
  end

  def sign_out(*)
    LoginDeSistema.limpar
    Capybara.reset_sessions!
  end
end

Warden::Manager.on_request do |proxy|
  next unless LoginDeSistema.ultimo

  if proxy.request.path == "/users/sign_out"
    LoginDeSistema.limpar
  elsif LoginDeSistema.usuarios.values.exclude?(proxy.user(:user))
    # Navegador ainda sem login (ou com um usuário que não vale mais): entra o último que fez sign_in.
    proxy.set_user(LoginDeSistema.ultimo, scope: :user)
  end
end

RSpec.configure do |config|
  config.include LoginDeSistema, type: :system
  config.after(:each, type: :system) { LoginDeSistema.limpar }
end
