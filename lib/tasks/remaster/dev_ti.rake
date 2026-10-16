# Cenário de "dia de caos" da TI, para ver o painel de acompanhamento (/ti/acompanhamento) com todo tipo
# de situação: chamados sem responsável há minutos, horas e dias, em várias prioridades; triagem parada;
# atendimento sem novidade; chamados esperando o solicitante ou impedidos há dias.
#
# SÓ em desenvolvimento. Apaga os chamados deste cenário (os dos usuários caos.*@siscom.dev) e recria
# com horários relativos a agora; os outros chamados do banco ficam como estão. Não manda notificações.
namespace :remaster do
  namespace :dev do
    desc "TI: cria o cenário de caos para o painel de acompanhamento (só desenvolvimento)"
    task ti_caos: :environment do
      abort "Só roda em desenvolvimento." unless Rails.env.development?

      senha = ENV.fetch("SENHA_USUARIOS_PADRAO", "Siscom@Dev2026")
      agora = Time.current.change(sec: 0)
      solicitacoes = Ti::Problema.ativo.order(:id).limit(12).to_a
      abort "Cadastre solicitações no catálogo da TI antes (bin/rails remaster:ti:catalogo_inicial)." if solicitacoes.empty?

      Ti::Chamado.transaction do
        pessoas = [ "ANA PAULA LIMA", "BRUNO COSTA FERREIRA", "CARLA MENDES SOUZA", "DANIEL ROCHA ALVES", "ELAINE BARBOSA NUNES", "FABIO TEIXEIRA GOMES",
                    "GABRIELA PINTO RAMOS", "HENRIQUE DIAS MOURA", "ISABELA CASTRO REIS", "JORGE ALMEIDA PIRES" ].each_with_index.map do |nome, i|
          user = User.find_or_initialize_by(email: "caos.pessoa#{i + 1}@siscom.dev")
          user.assign_attributes(nome: nome, status: true, deve_trocar_senha: false)
          user.assign_attributes(password: senha, password_confirmation: senha) if user.new_record?
          user.save!
          user
        end
        apagados = Ti::Chamado.where(solicitante: pessoas).destroy_all.size
        tecnico = User.find_by!(email: "ti.tecnico@siscom.dev")
        triador = User.find_by!(email: "ti.triador@siscom.dev")
        supervisor = User.find_by!(email: "ti.supervisor@siscom.dev")
        unidades = Rh::Unidade.where.not(sigla: [ nil, "" ]).order(:id).limit(8).map { |u| [ u.id, [ u.sigla, u.nome ].compact_blank.join(" - ") ] }
        unidades = [ [ nil, "NUINFO - NÚCLEO DE INFORMÁTICA" ] ] if unidades.empty?
        contador = 0

        # Cria o chamado já na etapa pedida. `aberto` é há quanto tempo foi aberto; `parado` é há quanto tempo está sem novidade.
        criar = lambda do |status, aberto:, parado: aberto, prioridade: "normal", **outros|
          contador += 1
          pessoa = pessoas[contador % pessoas.size]
          unidade = unidades[contador % unidades.size]
          chamado = Ti::Chamado.new({ problema: solicitacoes[contador % solicitacoes.size], status: status, prioridade: prioridade, solicitante: pessoa,
                                      solicitante_nome: pessoa.nome, solicitante_email: pessoa.email, rh_unidade_id: unidade.first, unidade_nome: unidade.last,
                                      aberto_em: agora - aberto }.merge(outros))
          chamado.save!(validate: false)
          chamado.eventos.create!(tipo: "aberto", para_status: "aberto", nota: "Chamado aberto pelo solicitante.", ator: pessoa, ator_nome: pessoa.nome, ocorrido_em: agora - aberto)
          chamado.update_columns(created_at: agora - aberto, updated_at: agora - parado)
          chamado
        end

        # 1. Aguardando atendimento (sem responsável)
        criar.call("aberto", aberto: 10.minutes)
        criar.call("aberto", aberto: 50.minutes)
        criar.call("aberto", aberto: 150.minutes)
        criar.call("aberto", aberto: 5.hours)
        criar.call("aberto", aberto: 11.hours)
        criar.call("aberto", aberto: 3.days)
        criar.call("aberto", aberto: 20.minutes, prioridade: "critica")
        criar.call("aberto", aberto: 70.minutes, prioridade: "critica")
        criar.call("aberto", aberto: 45.minutes, prioridade: "urgente")
        criar.call("aberto", aberto: 3.hours, prioridade: "alta")
        criar.call("aguardando_tecnico", aberto: 6.hours, triador: triador, triado_em: agora - 5.hours, nota_triagem: "Precisa de visita ao local.")
        criar.call("aguardando_tecnico", aberto: 2.hours, triador: triador, triado_em: agora - 25.minutes, nota_triagem: "Trocar o cabo de rede.", prioridade: "alta")
        # 2. Em triagem
        criar.call("em_triagem", aberto: 40.minutes, triador: triador, triado_em: agora - 15.minutes)
        criar.call("em_triagem", aberto: 4.hours, triador: triador, triado_em: agora - 3.hours)
        criar.call("em_triagem", aberto: 2.days, triador: triador, triado_em: agora - 1.day)
        criar.call("em_triagem", aberto: 90.minutes, triador: triador, triado_em: agora - 50.minutes, prioridade: "urgente")
        # 3. Em atendimento
        criar.call("em_atendimento", aberto: 2.hours, parado: 30.minutes, responsavel: tecnico)
        criar.call("em_atendimento", aberto: 1.day, parado: 10.hours, responsavel: tecnico)
        criar.call("em_atendimento", aberto: 3.days, parado: 30.hours, responsavel: tecnico)
        criar.call("em_atendimento", aberto: 8.days, parado: 5.days, responsavel: supervisor)
        criar.call("em_atendimento", aberto: 3.hours, parado: 90.minutes, responsavel: tecnico, prioridade: "critica")
        criar.call("em_atendimento", aberto: 9.hours, parado: 5.hours, responsavel: supervisor, prioridade: "urgente")
        criar.call("em_atendimento", aberto: 2.days, parado: 6.hours, responsavel: tecnico, prioridade: "alta")
        # 4. Parados
        criar.call("aguardando_solicitante", aberto: 1.day, parado: 3.hours, responsavel: tecnico, nota_triagem: "Qual é a sala?")
        criar.call("aguardando_solicitante", aberto: 3.days, parado: 30.hours, responsavel: tecnico, nota_triagem: "Informe o número do patrimônio.")
        criar.call("aguardando_solicitante", aberto: 9.days, parado: 6.days, responsavel: tecnico, nota_triagem: "Envie a foto do erro.")
        criar.call("impedido", aberto: 2.days, parado: 50.hours, responsavel: tecnico, nota_triagem: "Aguardando peça do fornecedor.")
        criar.call("impedido", aberto: 12.days, parado: 9.days, responsavel: supervisor, nota_triagem: "Sem acesso ao prédio.", prioridade: "alta")
        # 5. Encerrados (não aparecem no painel)
        criar.call("concluido", aberto: 1.day, parado: 2.hours, responsavel: tecnico, concluido_em: agora - 2.hours)
        criar.call("cancelado", aberto: 2.days, parado: 1.day)

        Ti::Configuracao.atual.update!(senha_do_painel: ENV.fetch("SENHA_DO_PAINEL", "painel2026"))
        cenario = Ti::Chamado.where(solicitante: pessoas)
        puts "Apagados #{apagados} chamados do cenário; criados #{cenario.count} (#{cenario.group(:status).count.map { |status, n| "#{n} #{status}" }.join(', ')})."
        puts "Painel: /ti/acompanhamento (senha do painel em USUARIOS-PADRAO.md)."
      end
    end
  end
end
