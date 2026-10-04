namespace :remaster do
  namespace :ti do
    desc "Carga inicial do catálogo da TI a partir do siscom antigo (categorias, solicitações, campos, perfis de abertura, grupo técnico). Idempotente; não migra chamados."
    task catalogo_inicial: :environment do
      relatorio = Ti::Importacao::CatalogoInicial.call

      puts "TI: #{relatorio}"
    end
  end
end
