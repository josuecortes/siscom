namespace :remaster do
  namespace :ti do
    desc "Carga inicial do catálogo da TI a partir do siscom antigo (categorias, solicitações, campos, perfis de abertura, grupo técnico). Idempotente; não migra chamados."
    task catalogo_inicial: :environment do
      relatorio = Ti::Importacao::CatalogoInicial.call

      puts "TI: #{relatorio}"
    end

    desc "Perfis de abertura da TI (SERVIDORES padrão; ESCOLAS e ADMINISTRATIVO, servidores e gestão), a partir do siscom antigo. Idempotente."
    task perfis_de_abertura: :environment do
      relatorio = Ti::Importacao::PerfisDeAbertura.call
      puts "TI, perfis de abertura: #{relatorio}"
      Ti::PerfilAbertura.ativo.order(:nome).each do |perfil|
        puts format("  %-30s %5d pessoa(s)  %s", perfil.nome, perfil.vinculos_de_usuario.count, perfil.padrao? ? "(padrão: vale para todos)" : "")
      end
    end
  end
end
