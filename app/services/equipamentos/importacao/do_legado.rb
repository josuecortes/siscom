module Equipamentos
  module Importacao
    # Traz os equipamentos e as movimentações do siscom antigo (equipamentos + movimentacao_equipamentos +
    # item_movimentacoes) para o módulo novo. É o mesmo script em desenvolvimento e em produção.
    #
    # Idempotente: cada equipamento e cada movimentação guardam o id antigo em `legacy_id`; rodar de novo só traz
    # o que falta. Não manda notificação. Nenhuma coluna foi afrouxada: onde o formato novo exige algo que o
    # antigo não tinha, o dado é ajustado aqui (de-para em docs/refactor-remaster/06-migracao-dos-equipamentos.md):
    #
    # - o histórico, que era um JSON dentro do equipamento, vira linhas de `equipamentos_eventos`;
    # - a movimentação "inicial" (origem = destino, criada no cadastro) não vem: o cadastro já está no histórico;
    # - equipamento com envio ainda pendente chega "em movimentação", e quem recebe vê em Meus equipamentos;
    # - o antigo não guardava quem deu o recebido nem quem cancelou → quem recebe e quem criou, como era a regra;
    # - switch sem MAC ou sem ativo de rede (o novo exige) → "NÃO INFORMADO", para corrigir na edição;
    # - o código de kit antigo (a hora do cadastro, ex.: 20251205145840) é mantido; os novos saem como KIT-000001.
    #
    # Número: o equipamento antigo 123 continua 123 e a movimentação antiga 45 vira MV-000045, sempre que o id
    # está livre; no fim as sequências são acertadas. Permissões: ninguém vira gestor sozinho (decisão do Josue,
    # 2026-10-06); só `ADMINISTRADOR_INICIAL` recebe a de administrador, e concede as demais.
    class DoLegado
      STATUS = { 0 => "ativo", 1 => "inativo", 2 => "em_manutencao", 3 => "descartado" }.freeze
      # Ação do histórico antigo => tipo do evento novo.
      EVENTOS = { "cadastro" => "cadastrado", "movimentacao" => "movimentacao_recebida", "transferencia" => "movimentacao_recebida", "alteracao_status" => "situacao_alterada" }.freeze
      DA_LINHA = { "pendente" => "pendente", "recebido" => "recebido", "cancelada" => "cancelado" }.freeze
      NAO_INFORMADO = "NÃO INFORMADO".freeze
      ADMINISTRADOR_INICIAL = "josue.cort3s@gmail.com".freeze
      COPIADOS = %i[tipo_equipamento descricao marca modelo numero_serial numero_patrimonio outra_identificacao codigo_kit identificacao_kit contrato processo garantia host ip mac
                    ativo_de_rede localizacao_fisica rack].freeze

      Relatorio = Data.define(:antigos, :importados, :ja_existiam, :ignorados, :eventos, :movimentacoes_antigas, :movimentacoes, :movimentacoes_ja_existiam, :linhas, :em_movimentacao,
                              :ajustados, :administrador) do
        def to_s
          "equipamentos antigos: #{antigos}; importados agora: #{importados}; já estavam: #{ja_existiam}; registros de histórico: #{eventos}; " \
            "movimentações antigas (sem as iniciais): #{movimentacoes_antigas}; importadas agora: #{movimentacoes}; já estavam: #{movimentacoes_ja_existiam}; " \
            "equipamentos nas movimentações: #{linhas}; em movimentação agora: #{em_movimentacao}; ajustados: #{ajustados.size}; ignorados: #{ignorados.size}; administrador: #{administrador}"
        end
      end

      def self.call(...) = new(...).call

      def call
        @ignorados = []
        @ajustados = []
        @contagem = Hash.new(0)
        ::Legado::Api.cada_equipamento { |lote| importar_equipamentos(lote) }
        ::Legado::Api.cada_movimentacao_de_equipamentos { |lote| importar_movimentacoes(lote) }
        acertar_sequencias

        Relatorio.new(antigos: ::Legado::Api.total_de_equipamentos, importados: @contagem[:itens], ja_existiam: @contagem[:itens_ja], ignorados: @ignorados, eventos: @contagem[:eventos],
                      movimentacoes_antigas: ::Legado::Api.total_de_movimentacoes_de_equipamentos, movimentacoes: @contagem[:movimentacoes], movimentacoes_ja_existiam: @contagem[:movimentacoes_ja],
                      linhas: @contagem[:linhas], em_movimentacao: Equipamentos::Item.where.not(legacy_id: nil).em_movimentacao.count, ajustados: @ajustados, administrador: conceder_administrador)
      end

      private

      # --- Equipamentos ---

      def importar_equipamentos(lote)
        ids = lote.pluck(:id)
        feitos = Equipamentos::Item.where(legacy_id: ids).pluck(:legacy_id).to_set
        livres = ids.to_set - Equipamentos::Item.where(id: ids).pluck(:id)
        usuarios = usuarios_de(lote.flat_map { |antigo| [ antigo[:user_id] ] + historico(antigo).pluck("usuario_id") })
        unidades = unidades_de(lote.pluck(:unidade_id))

        lote.each do |antigo|
          next @contagem[:itens_ja] += 1 if feitos.include?(antigo[:id])

          unidade = unidades[antigo[:unidade_id]]
          next @ignorados << "equipamento #{antigo[:id]}: a unidade antiga #{antigo[:unidade_id]} não existe no RH novo" unless unidade

          item = montar(antigo, unidade, usuarios)
          item.id = antigo[:id] if livres.include?(antigo[:id])
          next @ignorados << "equipamento #{antigo[:id]}: #{item.errors.full_messages.to_sentence}" unless item.valid?

          Equipamentos::Item.transaction do
            item.save!
            gravar_historico(item, antigo, usuarios)
          end
          @contagem[:itens] += 1
        end
      end

      def montar(antigo, unidade, usuarios)
        cadastro = historico(antigo).find { |linha| linha["acao"] == "cadastro" }
        item = Equipamentos::Item.new(antigo.slice(*COPIADOS))
        item.assign_attributes(status: STATUS.fetch(antigo[:status], "ativo"), situacao: "disponivel", rh_unidade_id: unidade.id, unidade_nome: unidade.sigla_e_nome, legacy_id: antigo[:id],
                               cadastrado_por: usuarios[cadastro&.dig("usuario_id")] || usuarios[antigo[:user_id]], created_at: antigo[:created_at], updated_at: antigo[:updated_at])
        completar_switch(item)
        item
      end

      # O novo exige MAC e ativo de rede no switch; o antigo passou a exigir depois de já haver switch cadastrado.
      def completar_switch(item)
        return unless item.switch? && (item.mac.blank? || item.ativo_de_rede.blank?)

        faltas = { mac: "MAC", ativo_de_rede: "ativo de rede" }.select { |campo, _| item[campo].blank? }
        item.mac = "#{NAO_INFORMADO} (#{item.legacy_id})" if item.mac.blank? # o MAC é único
        item.ativo_de_rede ||= NAO_INFORMADO
        @ajustados << "equipamento #{item.legacy_id} (switch): #{faltas.values.to_sentence} não informado(s) no siscom antigo"
      end

      def gravar_historico(item, antigo, usuarios)
        linhas = historico(antigo)
        linhas = [ { "acao" => "cadastro", "data" => antigo[:created_at].iso8601, "usuario_id" => antigo[:user_id], "detalhes" => "Equipamento cadastrado no sistema." } ] + linhas if linhas.none? { |linha| linha["acao"] == "cadastro" }
        linhas.each do |linha|
          ator = usuarios[linha["usuario_id"]]
          item.eventos.create!(tipo: EVENTOS.fetch(linha["acao"].to_s, "legado"), ator: ator, ator_nome: linha["usuario"].presence || ator&.nome, nota: linha["detalhes"].to_s.squish.presence, mudancas: {},
                               ocorrido_em: momento(linha["data"]) || antigo[:created_at])
          @contagem[:eventos] += 1
        end
        nota = @ajustados.find { |ajuste| ajuste.start_with?("equipamento #{item.legacy_id} ") }
        item.registrar_evento("legado", nil, "Trazido do siscom antigo: #{nota.split(': ', 2).last}. Corrija na edição do equipamento.") if nota
      end

      def historico(antigo) = Array(antigo[:historico_movimentacoes]).grep(Hash)

      def momento(texto)
        Time.zone.parse(texto.to_s)
      rescue ArgumentError
        nil
      end

      # --- Movimentações ---

      def importar_movimentacoes(lote)
        ids = lote.pluck(:id)
        feitas = Equipamentos::Movimentacao.where(legacy_id: ids).pluck(:legacy_id).to_set
        livres = ids.to_set - Equipamentos::Movimentacao.where(id: ids).pluck(:id)
        usuarios = usuarios_de(lote.flat_map { |antiga| antiga.values_at(:user_id, :responsavel_id) })
        unidades = unidades_de(lote.flat_map { |antiga| antiga.values_at(:unidade_origem_id, :unidade_destino_id) })
        linhas = ::Legado::Api.itens_das_movimentacoes_de_equipamentos(ids)
        itens = Equipamentos::Item.where(legacy_id: linhas.values.flatten.pluck(:equipamento_id)).index_by(&:legacy_id)

        lote.each do |antiga|
          next @contagem[:movimentacoes_ja] += 1 if feitas.include?(antiga[:id])

          recusa = recusa_da_movimentacao(antiga, usuarios, unidades, linhas.fetch(antiga[:id], []), itens)
          next @ignorados << "movimentação #{antiga[:id]}: #{recusa}" if recusa

          Equipamentos::Movimentacao.transaction { importar_movimentacao(antiga, usuarios, unidades, linhas.fetch(antiga[:id], []), itens, livres.include?(antiga[:id])) }
          @contagem[:movimentacoes] += 1
        end
      end

      def recusa_da_movimentacao(antiga, usuarios, unidades, linhas, itens)
        return "quem criou ou quem recebe não existe mais" unless usuarios[antiga[:user_id]] && usuarios[antiga[:responsavel_id]]
        return "a unidade de origem ou de destino não existe no RH novo" unless unidades[antiga[:unidade_origem_id]] && unidades[antiga[:unidade_destino_id]]

        fora = linhas.find { |linha| itens[linha[:equipamento_id]].nil? }
        "o equipamento antigo #{fora[:equipamento_id]} não foi importado" if fora
      end

      def importar_movimentacao(antiga, usuarios, unidades, linhas, itens, id_livre)
        origem, destino = unidades.values_at(antiga[:unidade_origem_id], antiga[:unidade_destino_id])
        criador, responsavel = usuarios.values_at(antiga[:user_id], antiga[:responsavel_id])
        aberta = antiga[:status] == "em_andamento"
        envio = Equipamentos::Movimentacao.new(tipo: "movimentacao", status: Equipamentos::Movimentacao::STATUS.key?(antiga[:status]) ? antiga[:status] : "concluida",
                                               origem_rh_unidade_id: origem.id, origem_nome: origem.sigla_e_nome, destino_rh_unidade_id: destino.id, destino_nome: destino.sigla_e_nome,
                                               responsavel: responsavel, responsavel_nome: responsavel.nome, criada_por: criador, criada_por_nome: criador.nome,
                                               descricao: antiga[:descricao].to_s.squish.presence, encerrada_em: (antiga[:updated_at] unless aberta), legacy_id: antiga[:id],
                                               created_at: antiga[:data_movimentacao] || antiga[:created_at], updated_at: antiga[:updated_at])
        envio.id = antiga[:id] if id_livre # MV-000045 para a movimentação antiga 45
        envio.save!
        linhas.each { |linha| importar_linha(envio, linha, itens.fetch(linha[:equipamento_id]), aberta) }
      end

      def importar_linha(envio, linha, item, aberta)
        status = DA_LINHA.fetch(linha[:status].to_s, linha[:recebido] ? "recebido" : "pendente")
        status = "cancelado" if status == "pendente" && !aberta # envio encerrado não deixa equipamento preso
        envio.itens.create!(item: item, status: status, legacy_id: linha[:id], created_at: linha[:created_at], updated_at: linha[:updated_at],
                            recebido_em: (linha[:data_recebimento] || linha[:updated_at] if status == "recebido"), recebido_por: (envio.responsavel if status == "recebido"),
                            cancelado_em: (linha[:updated_at] if status == "cancelado"), cancelado_por: (envio.criada_por if status == "cancelado"))
        nota = "Movimentação #{envio.codigo}: de #{envio.origem_nome} para #{envio.destino_nome}, aos cuidados de #{envio.responsavel_nome}."
        item.registrar_evento("movimentacao_criada", envio.criada_por, nota, em: envio.created_at)
        item.registrar_evento("movimentacao_cancelada", envio.criada_por, "Movimentação #{envio.codigo} para #{envio.destino_nome}: envio cancelado.", em: linha[:updated_at]) if status == "cancelado"
        item.update_columns(situacao: "em_movimentacao") if status == "pendente" # rubocop:disable Rails/SkipsModelValidations -- mantém a data da última alteração antiga
        @contagem[:linhas] += 1
        @contagem[:eventos] += status == "cancelado" ? 2 : 1
      end

      # --- Apoio ---

      def usuarios_de(ids) = ::User.where(id: ids.compact.uniq).index_by(&:id)
      def unidades_de(ids) = ids.compact.uniq.index_with { |id| Rh::Api.unidade_do_legado(id) }

      def conceder_administrador
        user = Core::Api.conta_por_email(ADMINISTRADOR_INICIAL)
        return "#{ADMINISTRADOR_INICIAL} não tem conta" unless user

        resultado = Core::Api.conceder_pelo_sistema(user: user, modulo: "equipamentos", papel: "admin")
        resultado.sucesso? ? user.email : "#{user.email}: #{resultado.mensagem_de_erro}"
      end

      def acertar_sequencias
        %w[equipamentos_itens equipamentos_movimentacoes].each do |tabela|
          Equipamentos::Item.connection.execute("SELECT setval(pg_get_serial_sequence('#{tabela}', 'id'), GREATEST((SELECT COALESCE(MAX(id), 0) FROM #{tabela}), 1))")
        end
      end
    end
  end
end
