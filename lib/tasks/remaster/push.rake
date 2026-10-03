namespace :remaster do
  namespace :push do
    desc "Gera um par de chaves VAPID para as notificações push (configure no Dokku)."
    task gerar_chaves: :environment do
      par = WebPush.generate_key
      puts "VAPID_PUBLIC_KEY=#{par.public_key}"
      puts "VAPID_PRIVATE_KEY=#{par.private_key}"
    end
  end
end
