# Login dos system specs. O `sign_in` do Devise vale só para a PRÓXIMA requisição que chega ao
# servidor; com navegador de verdade, uma requisição atrasada do exemplo anterior (refresh do Turbo,
# busca de autocomplete) podia gastar esse login e o exemplo caía na tela de entrada, de vez em quando.
# Aqui o usuário fica valendo durante o exemplo inteiro: qualquer requisição sem ele é autenticada.
# Sair pelo sistema (DELETE /users/sign_out) desliga, para os specs de logout continuarem valendo.
module LoginDeSistema
  mattr_accessor :usuario

  def sign_in(user, **)
    LoginDeSistema.usuario = user
  end

  def sign_out(*)
    LoginDeSistema.usuario = nil
    Capybara.reset_sessions!
  end
end

Warden::Manager.on_request do |proxy|
  usuario = LoginDeSistema.usuario
  next unless usuario

  if proxy.request.path == "/users/sign_out"
    LoginDeSistema.usuario = nil
  elsif proxy.user(:user) != usuario
    proxy.set_user(usuario, scope: :user)
  end
end

RSpec.configure do |config|
  config.include LoginDeSistema, type: :system
  config.after(:each, type: :system) { LoginDeSistema.usuario = nil }
end
