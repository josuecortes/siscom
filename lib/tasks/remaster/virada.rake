# Virada do siscom antigo para o remaster: tudo o que precisa rodar DEPOIS do deploy, na ordem certa, num comando só.
# Roteiro completo (antes, durante, depois e como voltar): docs/refactor-remaster/07-virada-e-contingencia.md.
#
#   dokku run siscom bin/rails remaster:virada
#
# Cada passo é idempotente: se algo falhar no meio, corrija e rode de novo (só traz o que falta).
# As migrations não entram aqui: o Dokku já roda `db:migrate` no deploy (linha `release` do Procfile).
namespace :remaster do
  PASSOS_DA_VIRADA = [
    [ "remaster:core:importar", "Administração: permissões antigas (master → superadministrador, admin → administrador de usuários)" ],
    [ "remaster:rh:importar", "RH: tipos de unidade, unidades, funções, cargos, pessoas e lotações" ],
    [ "remaster:ti:catalogo_inicial", "TI: catálogo (categorias, solicitações, campos, perfis de abertura, grupo técnico)" ],
    [ "remaster:transporte:importar_papeis", "Transporte: permissões antigas (solicitante e técnico)" ],
    [ "remaster:migracao:chamados_de_ti", "TI: chamados antigos" ],
    [ "remaster:migracao:solicitacoes_de_transporte", "Transporte: requisições antigas" ],
    [ "remaster:migracao:equipamentos", "Equipamentos: equipamentos e movimentações antigos" ],
    [ "remaster:migracao:conferir", "Conferência: chamados e requisições, antigo contra novo" ],
    [ "remaster:migracao:conferir_equipamentos", "Conferência: equipamentos, antigo contra novo" ]
  ].freeze

  desc "Virada: roda, na ordem, todas as importações do siscom antigo e as conferências. Idempotente."
  task virada: :environment do
    inicio = Time.current
    diferencas = []
    PASSOS_DA_VIRADA.each_with_index do |(tarefa, descricao), indice|
      puts "\n=== #{indice + 1}/#{PASSOS_DA_VIRADA.size} #{descricao} (#{tarefa})"
      Rake::Task[tarefa].invoke
    rescue SystemExit => e
      # Importação que falha interrompe tudo; conferência com diferença deixa as outras rodarem e avisa no fim.
      raise unless tarefa.include?(":conferir")

      diferencas << "#{tarefa}: #{e.message}"
    end
    abort "\n=== ATENÇÃO: #{diferencas.join(' | ')} Não libere o sistema antes de entender a diferença (roteiro, seção 5)." if diferencas.any?
    puts "\n=== Virada concluída em #{(Time.current - inicio).round} s. Usuários: #{User.count}; pessoas no RH: #{Rh::Pessoa.count}; chamados de TI: #{Ti::Chamado.count}; " \
         "solicitações de transporte: #{Transporte::Solicitacao.count}; equipamentos: #{Equipamentos::Item.count}."
    puts "Próximo passo do roteiro: conferir no navegador e tirar o sistema da manutenção."
  end
end
