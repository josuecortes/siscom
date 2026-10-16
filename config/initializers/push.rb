# Notificações push (Web Push / VAPID).
# Produção: defina VAPID_PUBLIC_KEY e VAPID_PRIVATE_KEY (ex.: `dokku config:set`); gere o par com
# `bin/rails remaster:push:gerar_chaves`. Sem as chaves, o push fica desligado e o resto funciona.
# Desenvolvimento e teste: um par é gerado na primeira vez e guardado em tmp/vapid.json.
Rails.application.config.x.push = ActiveSupport::OrderedOptions.new.tap do |push|
  push.chave_publica = ENV["VAPID_PUBLIC_KEY"].presence
  push.chave_privada = ENV["VAPID_PRIVATE_KEY"].presence
  push.contato = ENV.fetch("VAPID_CONTATO", "mailto:josue.cort3s@gmail.com")
  # Serviços de push dos navegadores (Chrome/Edge/Android, Firefox, Safari/iOS, Windows).
  push.servicos = %w[fcm.googleapis.com push.services.mozilla.com push.apple.com notify.windows.com]
  push.servicos += %w[push.exemplo.test] if Rails.env.test?

  if push.chave_publica.blank? && Rails.env.local?
    arquivo = Rails.root.join("tmp/vapid.json")
    unless arquivo.exist?
      par = WebPush.generate_key
      arquivo.dirname.mkpath
      arquivo.write({ publica: par.public_key, privada: par.private_key }.to_json)
    end
    chaves = JSON.parse(arquivo.read)
    push.chave_publica = chaves["publica"]
    push.chave_privada = chaves["privada"]
  end

  push.ativo = push.chave_publica.present? && push.chave_privada.present?
end
