# Limites de requisição (rack-attack). Os usuários da SEED saem para a internet
# por poucos IPs compartilhados, então o limite por IP é folgado; o limite por
# e-mail e o bloqueio do Devise (10 tentativas) seguram a força bruta.
class Rack::Attack
  LOGIN = "/users/sign_in".freeze

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  throttle("login/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.post? && req.path == LOGIN
  end

  throttle("login/email", limit: 20, period: 10.minutes) do |req|
    req.params.dig("user", "email").to_s.strip.downcase.presence if req.post? && req.path == LOGIN
  end

  # Teto geral por IP contra abuso automatizado (não conta arquivos estáticos).
  throttle("geral/ip", limit: 1200, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  self.throttled_responder = lambda do |request|
    espera = (request.env["rack.attack.match_data"] || {})[:period].to_i
    mensagem = "Muitas tentativas em pouco tempo. Aguarde alguns minutos e tente novamente."
    [ 429, { "content-type" => "text/plain; charset=utf-8", "retry-after" => espera.to_s }, [ mensagem ] ]
  end
end
