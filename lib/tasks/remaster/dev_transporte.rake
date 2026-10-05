# Cenário de "dia de caos" do Transporte, para ver o painel de acompanhamento (/transporte/acompanhamento)
# com todo tipo de situação: pedidos sem aprovação com a saída chegando ou já passada, saídas atrasadas,
# serviços na rua há tempo demais, buscas vencidas. Pedido do Josue (2026-10-05).
#
# SÓ em desenvolvimento. APAGA todas as solicitações de transporte e recria o cenário com horários
# relativos a agora (rode de novo para "renovar" os atrasos). Grava com validate: false, porque várias
# situações (saída no passado) não passam nas regras da tela. Não manda notificações.
namespace :remaster do
  namespace :dev do
    desc "Transporte: apaga as solicitações e cria o cenário de caos para o painel de acompanhamento (só desenvolvimento)"
    task transporte_caos: :environment do
      abort "Só roda em desenvolvimento." unless Rails.env.development?

      senha = ENV.fetch("SENHA_USUARIOS_PADRAO", "Siscom@Dev2026")
      agora = Time.current.change(sec: 0)
      cpf = lambda do |n| # CPF válido a partir de um número
        base = format("%09d", 100_000_000 + n).chars.map(&:to_i)
        2.times { base << ((base.each_with_index.sum { |d, i| d * (base.size + 1 - i) } * 10) % 11 % 10) }
        base.join
      end
      usuario = lambda do |nome, email, papel|
        user = User.find_or_initialize_by(email: email)
        user.assign_attributes(nome: nome, status: true, deve_trocar_senha: false)
        user.assign_attributes(password: senha, password_confirmation: senha) if user.new_record?
        user.save!
        resultado = Core::Acessos::Conceder.call(user: user, modulo: "transporte", papel: papel, pelo_sistema: true)
        abort "Falha em #{email}: #{resultado.mensagem_de_erro}" if resultado.falha?
        user
      end

      Transporte::Solicitacao.transaction do
        apagadas = Transporte::Solicitacao.count
        Transporte::Solicitacao.destroy_all

        pessoas = [ "ANA PAULA LIMA", "BRUNO COSTA FERREIRA", "CARLA MENDES SOUZA", "DANIEL ROCHA ALVES", "ELAINE BARBOSA NUNES", "FABIO TEIXEIRA GOMES",
                    "GABRIELA PINTO RAMOS", "HENRIQUE DIAS MOURA", "ISABELA CASTRO REIS", "JORGE ALMEIDA PIRES" ].each_with_index.map do |nome, i|
          usuario.call(nome, "caos.pessoa#{i + 1}@siscom.dev", "solicitante")
        end
        motoristas = [ "MARCOS VIEIRA", "NILSON BATISTA", "OTAVIO CARDOSO", "PAULO HENRIQUE SALES", "RAIMUNDO NONATO", "SERGIO LOBATO", "TIAGO FURTADO", "VALDIR MONTEIRO" ]
                     .each_with_index.map do |nome, i|
          user = usuario.call("MOTORISTA #{nome}", "caos.motorista#{i + 1}@siscom.dev", "motorista")
          motorista = Transporte::Motorista.find_or_initialize_by(user: user)
          motorista.assign_attributes(nome: nome, cpf: cpf.call(500 + i), data_nascimento: Date.new(1980 + i, 3, 10), cnh_numero: format("CAOS%07d", i + 1),
                                      cnh_categoria: "D", cnh_validade: 2.years.from_now.to_date, status: "ativo")
          motorista.save!(validate: false)
          user
        end
        veiculos = [ %w[QLM1A01 TOYOTA HILUX], %w[QLM1A02 TOYOTA HILUX], %w[QLM1A03 FIAT STRADA], %w[QLM1A04 FIAT TORO], %w[QLM1A05 RENAULT DUSTER],
                     %w[QLM1A06 CHEVROLET S10], %w[QLM1A07 VOLKSWAGEN SAVEIRO], %w[QLM1A08 MITSUBISHI L200], %w[QLM1A09 FIAT DOBLO], %w[QLM1A10 RENAULT MASTER],
                     %w[QLM1A11 TOYOTA COROLLA], %w[QLM1A12 FIAT CRONOS] ].each_with_index.map do |(placa, marca, modelo), i|
          veiculo = Transporte::Veiculo.find_or_initialize_by(placa: placa)
          veiculo.assign_attributes(marca: marca, modelo: modelo, ano: 2019 + (i % 5), cor: %w[BRANCA PRATA PRETA][i % 3], capacidade: (modelo == "MASTER" ? 15 : 4),
                                    combustivel: "diesel", consumo_km_por_litro: 9.5, status: "ativo")
          veiculo.odometro_atual = [ veiculo.odometro_atual.to_i, 20_000 + (i * 3_000) ].max
          veiculo.save!
          veiculo
        end
        unidades = Rh::Unidade.where.not(sigla: [ nil, "" ]).order(:id).limit(8).map { |u| [ u.id, [ u.sigla, u.nome ].compact_blank.join(" - ") ] }
        unidades = [ [ nil, "NUINFO - NÚCLEO DE INFORMÁTICA" ] ] if unidades.empty?
        destinos = [ [ "SEAD", "Avenida FAB", "96", "Central" ], [ "Palácio do Setentrião", "Rua General Rondon", "259", "Central" ],
                     [ "Escola Estadual Tiradentes", "Avenida Padre Júlio Maria Lombaerd", "1900", "Santa Rita" ], [ "Hospital de Emergência", "Rua Hamilton Silva", "1648", "Central" ],
                     [ "Aeroporto de Macapá", "Rua Hildemar Maia", "3000", "Jardim Marco Zero" ], [ "Escola Estadual em Santana", "Avenida Santana", "1200", "Central" ] ]
        tecnico = User.find_by(email: "transporte.tecnico@siscom.dev") || pessoas.first
        contador = 0

        # Cria uma solicitação já na etapa pedida, com passageiro, destino e histórico coerentes.
        criar = lambda do |resumo, status:, saida:, modo: "so_deixar", tipo: "normal", **outros|
          contador += 1
          pessoa = pessoas[contador % pessoas.size]
          unidade = unidades[contador % unidades.size]
          aberta_em = [ saida - 3.days, agora - 6.days ].max
          s = Transporte::Solicitacao.new({ tipo: tipo, modo: modo, status: status, resumo: resumo, saida_em: saida, solicitante: pessoa, solicitante_nome: pessoa.nome,
                                            solicitante_email: pessoa.email, rh_unidade_id: unidade.first, unidade_nome: unidade.last,
                                            espera_horas: (2 if modo == "esperar_no_local"), busca_horas: (3 if modo == "buscar_depois"),
                                            retorno_em: (saida + 2.days if tipo == "viagem"), created_at: aberta_em }.merge(outros))
          s.assign_attributes(aprovada_por: tecnico, aprovada_em: aberta_em + 2.hours) unless status == "solicitada"
          s.save!(validate: false)
          s.passageiros.build(nome: pessoa.nome, cpf: cpf.call(contador), posicao: 0).save!(validate: false)
          nome, logradouro, numero, bairro = destinos[contador % destinos.size]
          s.destinos.build(nome: nome, logradouro: logradouro, numero: numero, bairro: bairro, cidade: (nome.include?("Santana") ? "Santana" : "Macapá"), uf: "AP", posicao: 0)
           .save!(validate: false)
          s.eventos.create!(tipo: "aberta", ator: pessoa, ator_nome: pessoa.nome, ocorrido_em: aberta_em)
          s.eventos.create!(tipo: "aprovada", ator: tecnico, ator_nome: tecnico.nome, ocorrido_em: aberta_em + 2.hours) unless status == "solicitada"
          s
        end
        # Põe um trecho em andamento (ou já finalizado) na solicitação.
        servico = lambda do |s, motorista, veiculo, inicio, trecho: "ida", fim: nil, grupo: nil|
          km = veiculo.odometro_atual
          s.servicos.build(trecho: trecho, motorista: motorista, motorista_nome: motorista.nome, veiculo: veiculo, placa: veiculo.placa, odometro_inicial: km,
                           odometro_final: (km + 18 if fim), iniciado_em: inicio, finalizado_em: fim, grupo: grupo || SecureRandom.uuid).save!(validate: false)
          s.eventos.create!(tipo: "servico_iniciado", ator: motorista, ator_nome: motorista.nome, ocorrido_em: inicio,
                            nota: "#{trecho == 'ida' ? 'Saída' : 'Saída para a busca'} com o veículo #{veiculo.placa}.")
          veiculo.update!(odometro_atual: km + 18) if fim
        end

        # 1. Aguardando aprovação
        criar.call("Reunião de planejamento na SEAD", status: "solicitada", saida: agora + 3.days)
        criar.call("Entrega de documentos no Palácio", status: "solicitada", saida: agora + 20.hours)
        criar.call("Visita técnica à escola", status: "solicitada", saida: agora + 90.minutes, modo: "esperar_no_local")
        criar.call("Levar equipamento para manutenção", status: "solicitada", saida: agora + 25.minutes)
        criar.call("Audiência no fórum", status: "solicitada", saida: agora - 40.minutes, modo: "buscar_depois")
        criar.call("Capacitação de professores", status: "solicitada", saida: agora - 2.days)
        criar.call("Viagem a Laranjal do Jari", status: "solicitada", saida: agora + 5.days, tipo: "viagem")
        reagendada = criar.call("Reunião com a coordenação", status: "reagendada", saida: agora + 5.hours, saida_anterior_em: agora + 1.hour,
                                motivo_reagendamento: "Veículo em manutenção pela manhã.", reagendada_por: tecnico, reagendada_em: agora - 30.minutes)
        reagendada.eventos.create!(tipo: "reagendada", ator: tecnico, ator_nome: tecnico.nome, ocorrido_em: agora - 30.minutes,
                                   nota: "Saída de #{I18n.l(agora + 1.hour, format: '%d/%m/%Y %H:%M')} para #{I18n.l(agora + 5.hours, format: '%d/%m/%Y %H:%M')}. Motivo: Veículo em manutenção pela manhã.")
        # 2. Aprovadas esperando a saída
        criar.call("Inspeção de obra amanhã cedo", status: "aprovada", saida: (agora + 1.day).change(hour: 9))
        criar.call("Reunião no Conselho de Educação", status: "aprovada", saida: agora + 3.hours)
        criar.call("Entrega de merenda", status: "aprovada", saida: agora + 100.minutes)
        criar.call("Buscar material na gráfica", status: "aprovada", saida: agora + 45.minutes, modo: "esperar_no_local")
        criar.call("Levar servidor ao aeroporto", status: "aprovada", saida: agora + 8.minutes)
        criar.call("Reunião na escola de Santana", status: "aprovada", saida: agora - 20.minutes, modo: "buscar_depois")
        criar.call("Vistoria de laboratório", status: "aprovada", saida: agora - 3.hours)
        criar.call("Entrega de ofício", status: "aprovada", saida: agora - 2.days)
        # 3. Em serviço
        servico.call(criar.call("Protocolo na SEAD", status: "em_servico", saida: agora - 25.minutes), motoristas[0], veiculos[0], agora - 20.minutes)
        servico.call(criar.call("Reunião com fornecedor", status: "em_servico", saida: agora - 95.minutes, modo: "esperar_no_local"), motoristas[1], veiculos[1], agora - 90.minutes)
        servico.call(criar.call("Entrega de livros", status: "em_servico", saida: agora - 190.minutes), motoristas[2], veiculos[2], agora - 3.hours)
        servico.call(criar.call("Manutenção de rede na escola", status: "em_servico", saida: agora - 6.hours, modo: "esperar_no_local", espera_horas: 1), motoristas[3], veiculos[3], agora - 6.hours)
        servico.call(criar.call("Viagem a Oiapoque", status: "em_servico", saida: agora - 4.days, tipo: "viagem", retorno_em: agora - 1.day), motoristas[4], veiculos[9], agora - 4.days)
        grupo = SecureRandom.uuid
        2.times do |i|
          servico.call(criar.call("Formação de gestores (turma #{i + 1})", status: "em_servico", saida: agora - 45.minutes, modo: "buscar_depois"),
                       motoristas[5], veiculos[5], agora - 40.minutes, grupo: grupo)
        end
        # 4. Aguardando busca
        busca = lambda do |resumo, prevista, motorista, veiculo|
          s = criar.call(resumo, status: "busca", saida: prevista - 4.hours, modo: "buscar_depois", busca_prevista_em: prevista)
          servico.call(s, motorista, veiculo, prevista - 4.hours, fim: prevista - 3.hours - 30.minutes)
          s
        end
        busca.call("Curso no centro de formação", agora + 2.hours, motoristas[6], veiculos[6])
        busca.call("Reunião no núcleo de tecnologia", agora + 50.minutes, motoristas[6], veiculos[6])
        busca.call("Atendimento na escola", agora + 20.minutes, motoristas[7], veiculos[7])
        busca.call("Audiência pública", agora - 35.minutes, motoristas[7], veiculos[7])
        busca.call("Conselho escolar", agora - 5.hours, motoristas[0], veiculos[8])
        busca.call("Evento da rede estadual", agora - 1.day, motoristas[1], veiculos[8])
        a_caminho = busca.call("Reunião de pais", agora - 10.minutes, motoristas[2], veiculos[10])
        servico.call(a_caminho, motoristas[6], veiculos[6], agora - 15.minutes, trecho: "busca")
        # 5. Encerradas (para as listas não ficarem vazias)
        concluida = criar.call("Entrega de documentos (ontem)", status: "concluida", saida: agora - 1.day, concluida_em: agora - 22.hours)
        servico.call(concluida, motoristas[3], veiculos[11], agora - 1.day, fim: agora - 22.hours)
        concluida.eventos.create!(tipo: "concluida", ator: motoristas[3], ator_nome: motoristas[3].nome, ocorrido_em: agora - 22.hours, nota: "Veículo #{veiculos[11].placa}, 18 km rodados.")
        cancelada = criar.call("Reunião desmarcada", status: "cancelada", saida: agora + 1.day, cancelada_por: tecnico, cancelada_em: agora - 2.hours, motivo_cancelamento: "Sem veículo disponível.")
        cancelada.eventos.create!(tipo: "cancelada", ator: tecnico, ator_nome: tecnico.nome, ocorrido_em: agora - 2.hours, nota: "Motivo: Sem veículo disponível.")

        Transporte::Configuracao.atual.update!(senha_do_painel: ENV.fetch("SENHA_DO_PAINEL", "painel2026"))
        puts "Apagadas #{apagadas} solicitações; criadas #{Transporte::Solicitacao.count} " \
             "(#{Transporte::Solicitacao.group(:status).count.map { |status, n| "#{n} #{status}" }.join(', ')})."
        puts "Painel: /transporte/acompanhamento (senha do painel em USUARIOS-PADRAO.md)."
      end
    end
  end
end
