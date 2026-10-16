namespace :remaster do
  namespace :core do
    desc "Importa os papéis antigos (Rolify) do Core: master → superadmin, admin → admin_usuarios. Idempotente."
    task importar: :environment do
      puts "Papéis antigos no banco: #{Legado::Api.contagem_de_papeis.sort_by { |_, total| -total }.to_h}"

      relatorio = Core::Importacao::Papeis.call(Core::Importacao::Papeis::MAPA_DO_CORE)

      puts "Core: #{relatorio}"
      relatorio.ignorados.each { |linha| puts "  ignorado: #{linha}" }
    end
  end
end
