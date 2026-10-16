namespace :remaster do
  namespace :rh do
    desc "Importa do siscom antigo: tipos de unidade, unidades, funções, cargos, pessoas e lotações. Idempotente."
    task importar: :environment do
      relatorio = Rh::Importacao::DoLegado.call

      puts "RH: #{relatorio}"
    end
  end
end
