module Transporte
  module Importacao
    # Traz as requisições de transporte do siscom antigo (requisicao_transportes + passageiros + destinos +
    # servico_transportes) para o módulo novo. É o mesmo script em desenvolvimento e em produção.
    #
    # Idempotente: cada solicitação guarda o id antigo em `legacy_id`; rodar de novo só traz o que falta.
    # Não manda notificação nem aviso em tempo real. Nenhuma coluna foi afrouxada: onde o formato novo exige
    # algo que o antigo não tinha, o dado é ajustado aqui (ver o de-para em
    # docs/refactor-remaster/05-migracao-dos-chamados-antigos.md). Resumo dos ajustes:
    #
    # - status "negada" não existe mais → cancelada, com o motivo da negação;
    # - tipo "urgente" não existe mais → normal, marcada como aberta fora do prazo;
    # - o antigo não tinha "o motorista deve…" → "só deixar";
    # - destino só tinha descrição, CEP e número → rua, bairro e cidade entram como "NÃO INFORMADO" (UF "AP");
    # - data de saída impossível (ano digitado errado, ex.: 20250) → usa a data do pedido, e o histórico registra;
    # - serviços antigos (motorista sem conta, veículo sem cadastro novo) → viram linhas do histórico;
    # - solicitada ou aprovada com saída há mais de `ANTIGA_DEPOIS_DE` → cancelada, motivo "data muito antiga"
    #   (decisão do Josue, 2026-10-05), para não aparecer como atrasada na operação e no painel de TV.
    #
    # Número: a requisição antiga 123 vira TR-000123 sempre que esse id está livre; no fim a sequência é acertada.
    class Solicitacoes
      # Status antigo (enum de requisicao_transporte.rb) => status novo.
      STATUS = { 1 => "solicitada", 2 => "aprovada", 3 => "aprovada", 4 => "cancelada", 5 => "cancelada", 6 => "concluida", 7 => "reagendada" }.freeze
      NOME_DO_STATUS_ANTIGO = { 1 => "aguardando", 2 => "aprovada", 3 => "em serviço", 4 => "negada", 5 => "cancelada", 6 => "finalizada", 7 => "reagendada" }.freeze
      URGENTE = 1
      VIAGEM = 3
      ANTIGA_DEPOIS_DE = 1.month
      NAO_INFORMADO = "NÃO INFORMADO".freeze
      FORMATO = "%d/%m/%Y %H:%M".freeze

      Relatorio = Data.define(:antigas, :importadas, :ja_existiam, :ignoradas, :por_status, :canceladas_por_data, :passageiros, :destinos, :servicos_no_historico) do
        def to_s
          "requisições antigas: #{antigas}; importadas agora: #{importadas}; já estavam: #{ja_existiam}; ignoradas: #{ignoradas.size}; por status: #{por_status}; " \
            "canceladas por data muito antiga: #{canceladas_por_data}; passageiros: #{passageiros}; destinos: #{destinos}; serviços antigos no histórico: #{servicos_no_historico}"
        end
      end

      def self.call(...) = new(...).call

      def initialize(agora: Time.current)
        @agora = agora
      end

      def call
        @ignoradas = []
        @contagem = Hash.new(0)
        Legado::Api.cada_requisicao_de_transporte { |lote| importar_lote(lote) }
        acertar_sequencia

        Relatorio.new(antigas: Legado::Api.total_de_requisicoes_de_transporte, importadas: @contagem[:importadas], ja_existiam: @contagem[:ja_existiam], ignoradas: @ignoradas,
                      por_status: Transporte::Solicitacao.where.not(legacy_id: nil).group(:status).count, canceladas_por_data: @contagem[:por_data],
                      passageiros: @contagem[:passageiros], destinos: @contagem[:destinos], servicos_no_historico: @contagem[:servicos])
      end

      private

      def importar_lote(lote)
        ids = lote.pluck(:id)
        feitas = Transporte::Solicitacao.where(legacy_id: ids).pluck(:legacy_id).to_set
        usuarios = ::User.where(id: lote.flat_map { |antiga| antiga.values_at(:user_id, :usuario_reagendou_id, :usuario_aceitou_negou_reagendamento_id) }.compact.uniq).index_by(&:id)
        unidades = lote.pluck(:unidade_id).compact.uniq.index_with { |id| Rh::Api.unidade_do_legado(id) }
        filhos = { passageiros: Legado::Api.passageiros_das_requisicoes(ids), destinos: Legado::Api.destinos_das_requisicoes(ids), servicos: Legado::Api.servicos_das_requisicoes(ids) }
        livres = ids.to_set - Transporte::Solicitacao.where(id: ids).pluck(:id)

        lote.each do |antiga|
          next @contagem[:ja_existiam] += 1 if feitas.include?(antiga[:id])

          solicitante = usuarios[antiga[:user_id]]
          next @ignoradas << "#{antiga[:id]}: solicitante não existe no sistema novo" unless solicitante

          Transporte::Solicitacao.transaction do
            importar(antiga, solicitante, usuarios, unidades[antiga[:unidade_id]], filhos.transform_values { |grupo| grupo.fetch(antiga[:id], []) }, livres.include?(antiga[:id]))
          end
        end
      end

      def importar(antiga, solicitante, usuarios, unidade, filhos, id_livre)
        solicitacao = montar(antiga, solicitante, usuarios, unidade)
        solicitacao.id = antiga[:id] if id_livre # TR-000123 para a requisição antiga 123
        muito_antiga = cancelar_se_muito_antiga(solicitacao)
        solicitacao.save!
        gravar_passageiros(solicitacao, filhos[:passageiros], solicitante)
        gravar_destinos(solicitacao, filhos[:destinos])
        gravar_historico(solicitacao, antiga, solicitante, usuarios, filhos[:servicos], muito_antiga)
        @contagem[:importadas] += 1
      end

      def montar(antiga, solicitante, usuarios, unidade)
        motivo = antiga[:motivo].to_s.strip.presence || "Motivo não informado no siscom antigo."
        viagem = antiga[:tipo] == VIAGEM
        saida = saida_valida(antiga)
        solicitacao = Transporte::Solicitacao.new(
          legacy_id: antiga[:id], tipo: (viagem ? "viagem" : "normal"), fora_do_padrao: antiga[:tipo] == URGENTE, modo: "so_deixar", status: STATUS.fetch(antiga[:status], "cancelada"),
          resumo: motivo.truncate(1000), saida_em: saida, retorno_em: (antiga[:data_hora_retorno] || saida + 1.minute if viagem), solicitante: solicitante,
          solicitante_nome: solicitante.nome.presence || solicitante.email, solicitante_email: solicitante.email, rh_unidade_id: unidade&.id, unidade_nome: unidade&.sigla_e_nome,
          aprovada_em: antiga[:data_hora_aprovada], aprovada_por: usuario_pelo_nome(antiga[:usuario_aprovou]), created_at: antiga[:created_at], updated_at: antiga[:updated_at]
        )
        reagendamento(solicitacao, antiga, usuarios)
        encerramento(solicitacao, antiga)
        solicitacao
      end

      # Havia saídas com o ano digitado errado (202408, 20250): data fora de 1 ano antes a 5 anos depois do pedido não vale.
      def saida_valida(antiga)
        saida = antiga[:data_hora_ida]
        saida && saida.between?(antiga[:created_at] - 1.year, antiga[:created_at] + 5.years) ? saida : antiga[:created_at]
      end

      def reagendamento(solicitacao, antiga, usuarios)
        return unless antiga[:requisicao_reagendada]

        solicitacao.assign_attributes(saida_anterior_em: antiga[:data_hora_ida_antiga], retorno_anterior_em: antiga[:data_hora_retorno_antiga],
                                      motivo_reagendamento: antiga[:motivo_reagendamento], reagendada_por: usuarios[antiga[:usuario_reagendou_id]],
                                      reagendada_em: antiga[:data_hora_reagendou], motivo_recusa_reagendamento: antiga[:motivo_negacao_reagendamento],
                                      reagendamento_respondido_em: antiga[:data_hora_aceitou_negou_reagendamento])
      end

      def encerramento(solicitacao, antiga)
        case antiga[:status]
        when 4
          solicitacao.assign_attributes(cancelada_em: antiga[:data_hora_negada] || antiga[:updated_at], cancelada_por: usuario_pelo_nome(antiga[:usuario_negou]),
                                        motivo_cancelamento: "Negada pelo setor de transporte: #{antiga[:motivo_negada].to_s.strip.presence || 'motivo não informado.'}")
        when 5
          solicitacao.assign_attributes(cancelada_em: antiga[:updated_at], motivo_cancelamento: "Cancelada no siscom antigo (o motivo não era registrado).")
        when 6
          solicitacao.concluida_em = antiga[:data_hora_finalizada] || antiga[:updated_at]
        end
      end

      # Pedido que ficou "aguardando" ou "aprovado" e cuja saída já passou há muito tempo: ninguém fechou no sistema antigo.
      def cancelar_se_muito_antiga(solicitacao)
        return false unless (solicitacao.solicitada? || solicitacao.aprovada?) && solicitacao.saida_em < @agora - ANTIGA_DEPOIS_DE

        @contagem[:por_data] += 1
        estava = solicitacao.nome_do_status.downcase
        solicitacao.assign_attributes(status: "cancelada", cancelada_em: @agora,
                                      motivo_cancelamento: "Cancelada na migração do siscom antigo: data muito antiga (saída em #{I18n.l(solicitacao.saida_em, format: FORMATO)}, " \
                                                           "estava como \"#{estava}\" e nunca foi encerrada).")
        true
      end

      def gravar_passageiros(solicitacao, antigos, solicitante)
        antigos = [ { nome: solicitante.nome, cpf: nil } ] if antigos.empty? # o novo sempre tem ao menos um passageiro: quem pediu
        antigos.each_with_index do |antigo, posicao|
          passageiro = solicitacao.passageiros.build(nome: antigo[:nome].to_s.squish.presence || NAO_INFORMADO, cpf: Cpf.digitos(antigo[:cpf]).presence || "00000000000", posicao: posicao)
          passageiro.save!(validate: false) # CPF antigo incompleto ou inválido entra como estava (a coluna só exige que exista)
          @contagem[:passageiros] += 1
        end
      end

      # O destino antigo só tinha descrição, CEP e número: o que o formato novo exige e não existia entra como "NÃO INFORMADO".
      def gravar_destinos(solicitacao, antigos)
        antigos = [ { descricao: NAO_INFORMADO } ] if antigos.empty?
        antigos.each_with_index do |antigo, posicao|
          numero = antigo[:numero].to_i.positive? ? antigo[:numero].to_s : "S/N"
          solicitacao.destinos.create!(nome: antigo[:descricao].to_s.squish.presence&.truncate(200) || NAO_INFORMADO, cep: antigo[:cep],
                                       logradouro: antigo[:logradouro].to_s.squish.presence || NAO_INFORMADO, numero: numero,
                                       bairro: antigo[:bairro].to_s.squish.presence || NAO_INFORMADO, cidade: antigo[:cidade].to_s.squish.presence || NAO_INFORMADO, uf: "AP", posicao: posicao)
          @contagem[:destinos] += 1
        end
      end

      def gravar_historico(solicitacao, antiga, solicitante, usuarios, servicos, muito_antiga)
        evento = lambda do |tipo, em, ator, nome, nota|
          solicitacao.eventos.create!(tipo: tipo, ator: ator, ator_nome: ator&.nome || nome.to_s.squish.presence || "Siscom antigo", nota: nota.to_s.squish.presence,
                                      ocorrido_em: em || antiga[:updated_at], created_at: em || antiga[:updated_at], updated_at: em || antiga[:updated_at])
        end
        completo = antiga[:motivo].to_s.strip
        evento.call("aberta", antiga[:created_at], solicitante, nil,
                    "Migrada do siscom antigo (requisição nº #{antiga[:id]}, #{'urgente, ' if antiga[:tipo] == URGENTE}situação \"#{NOME_DO_STATUS_ANTIGO[antiga[:status]]}\")." \
                    "#{" Motivo completo: #{completo}" if completo.length > 1000}" \
                    "#{" A data de saída gravada no siscom antigo era impossível (#{antiga[:data_hora_ida].to_fs(:db)}): foi usada a data do pedido." if antiga[:data_hora_ida] && saida_valida(antiga) != antiga[:data_hora_ida]}")
        evento.call("aprovada", antiga[:data_hora_aprovada], solicitacao.aprovada_por, antiga[:usuario_aprovou], nil) if antiga[:data_hora_aprovada]
        historico_do_reagendamento(evento, solicitacao, antiga, usuarios)
        servicos.each do |servico|
          @contagem[:servicos] += 1
          km = servico[:km_inicial] && servico[:km_final] ? " Km #{servico[:km_inicial]} a #{servico[:km_final]} (#{servico[:km_final] - servico[:km_inicial]} km)." : ""
          evento.call("servico_iniciado", servico[:created_at], nil, servico[:motorista_nome],
                      "Serviço registrado no siscom antigo: motorista #{servico[:motorista_nome] || 'não informado'}, veículo #{servico[:placa] || 'não informado'}.#{km} #{servico[:observacoes]}")
        end
        case antiga[:status]
        when 4 then evento.call("cancelada", solicitacao.cancelada_em, solicitacao.cancelada_por, antiga[:usuario_negou], solicitacao.motivo_cancelamento)
        when 5 then evento.call("cancelada", solicitacao.cancelada_em, nil, nil, solicitacao.motivo_cancelamento)
        when 6 then evento.call("concluida", solicitacao.concluida_em, nil, antiga[:usuario_finalizou], "Serviço finalizado no siscom antigo.")
        end
        evento.call("cancelada", @agora, nil, "Migração do siscom antigo", solicitacao.motivo_cancelamento) if muito_antiga
      end

      def historico_do_reagendamento(evento, solicitacao, antiga, usuarios)
        return unless antiga[:requisicao_reagendada]

        de = antiga[:data_hora_ida_antiga] && I18n.l(antiga[:data_hora_ida_antiga], format: FORMATO)
        evento.call("reagendada", antiga[:data_hora_reagendou], solicitacao.reagendada_por, nil,
                    "#{"Saída de #{de} para #{I18n.l(solicitacao.saida_em, format: FORMATO)}. " if de}Motivo: #{antiga[:motivo_reagendamento]}")
        return unless antiga[:data_hora_aceitou_negou_reagendamento]

        recusou = antiga[:motivo_negacao_reagendamento].present?
        evento.call((recusou ? "reagendamento_recusado" : "reagendamento_aceito"), antiga[:data_hora_aceitou_negou_reagendamento],
                    usuarios[antiga[:usuario_aceitou_negou_reagendamento_id]], nil, ("Motivo: #{antiga[:motivo_negacao_reagendamento]}" if recusou))
      end

      # O siscom antigo guardava só o nome de quem aprovou ou negou; liga à conta quando o nome é de uma pessoa só.
      def usuario_pelo_nome(nome)
        nome = nome.to_s.squish
        return nil if nome.blank?

        (@por_nome ||= {})[nome] ||= ::User.where(nome: nome).limit(2).to_a.then { |achados| achados.one? ? achados.first : nil }
      end

      def acertar_sequencia
        Transporte::Solicitacao.connection.execute(
          "SELECT setval(pg_get_serial_sequence('transporte_solicitacoes', 'id'), GREATEST((SELECT COALESCE(MAX(id), 0) FROM transporte_solicitacoes), 1))"
        )
      end
    end
  end
end
