module Ti
  module Importacao
    # Traz os chamados de TI do siscom antigo (requisicao_tis + mensagens + anexos) para o módulo novo,
    # para o histórico ficar junto com os chamados novos. É o mesmo script em desenvolvimento e em produção.
    #
    # Idempotente: cada chamado guarda o id antigo em `legacy_id`; rodar de novo só traz o que falta.
    # Não manda notificação nem aviso em tempo real. Nenhuma coluna foi afrouxada: onde o formato novo
    # exige algo que o antigo não tinha, o dado é ajustado aqui (ver o de-para em
    # docs/refactor-remaster/05-migracao-dos-chamados-antigos.md).
    #
    # Número: o chamado antigo 123 vira TI-000123 (o id novo é o id antigo) sempre que esse id está livre;
    # se já houver um chamado novo com esse id, recebe o próximo número. No fim a sequência é acertada.
    class Chamados
      # Status antigo (enum de requisicao_ti.rb) => status novo.
      STATUS = { 1 => "aberto", 2 => "em_atendimento", 3 => "concluido", 4 => "cancelado", 5 => "finalizado" }.freeze
      # Coluna antiga => [rótulo do campo no formulário novo, tipo do campo criado quando a solicitação não o tem].
      CAMPOS = {
        observacoes: [ "Observações", "texto_longo" ], nome: [ "Nome completo", "texto" ], email: [ "E-mail", "texto" ], cpf: [ "CPF", "texto" ], rg: [ "RG", "texto" ],
        data_nascimento: [ "Data de nascimento", "data" ], celular: [ "Celular", "texto" ], cargo_id: [ "Cargo", "texto" ], funcao_id: [ "Função", "texto" ],
        estado: [ "Estado", "texto" ], municipio: [ "Município", "texto" ], perfil: [ "Perfil", "texto_longo" ], periodo_inicio: [ "Início do período", "data" ],
        periodo_fim: [ "Fim do período", "data" ], unidade_destino: [ "Unidade/pasta de destino", "texto_longo" ], nae: [ "NAE da escola", "texto" ],
        permissao_drive: [ "Permissão na pasta do Google Drive", "texto_longo" ], nome_arquivo: [ "Nome do arquivo a ser excluído", "texto_longo" ],
        prodoc_nome_da_instituicao_externa: [ "Nome da instituição externa", "texto" ], prodoc_sigla_da_instituicao_externa: [ "Sigla da instituição externa", "texto" ],
        prodoc_nome_unidade_organizacional_externa: [ "Nome da unidade organizacional externa", "texto" ],
        prodoc_sigla_unidade_organizacional_externa: [ "Sigla da unidade organizacional externa", "texto" ],
        prodoc_responsavel_instituicao_externa: [ "Responsável da instituição externa", "texto" ],
        prodoc_cargo_do_responsavel_instituicao_externa: [ "Cargo do responsável", "texto" ],
        prodoc_pronome_responsavel_instituicao_externa: [ "Pronome do responsável", "texto" ], prodoc_cep_instituicao_externa: [ "CEP da instituição externa", "texto" ],
        prodoc_cidade_instituicao_externa: [ "Cidade da instituição externa", "texto" ], prodoc_uf_instituicao_externa: [ "UF da instituição externa", "texto" ]
      }.freeze
      # Anexo antigo (nome no Active Storage) => rótulo do campo de arquivo.
      ANEXOS = { "carta" => "Carta de apresentação ou decreto de nomeação", "decreto" => "Carta de apresentação ou decreto de nomeação", "prodoc" => "Documento do Prodoc" }.freeze
      AJUDA_DO_CAMPO_ANTIGO = "Campo do siscom antigo: existe só para guardar o dado dos chamados migrados.".freeze
      AVALIACOES = { 5 => "Muito bom", 4 => "Bom", 3 => "Normal", 2 => "Ruim", 1 => "Péssimo" }.freeze
      ENCERRADA = "Conversa do siscom antigo: fica só para consulta.".freeze

      Relatorio = Data.define(:antigos, :importados, :ja_existiam, :ignorados, :por_status, :valores, :mensagens, :campos_criados) do
        def to_s
          "chamados antigos: #{antigos}; importados agora: #{importados}; já estavam: #{ja_existiam}; ignorados: #{ignorados.size}; " \
            "por status: #{por_status}; dados informados: #{valores}; mensagens: #{mensagens}; campos criados para o legado: #{campos_criados}"
        end
      end

      def self.call(...) = new(...).call

      def call
        @ignorados = []
        @contagem = Hash.new(0)
        carregar_referencias
        Legado::Api.cada_requisicao_de_ti { |lote| importar_lote(lote) }
        acertar_sequencia

        Relatorio.new(antigos: Legado::Api.total_de_requisicoes_de_ti, importados: @contagem[:importados], ja_existiam: @contagem[:ja_existiam], ignorados: @ignorados,
                      por_status: Ti::Chamado.where.not(legacy_id: nil).group(:status).count, valores: @contagem[:valores], mensagens: @contagem[:mensagens],
                      campos_criados: @contagem[:campos])
      end

      private

      def carregar_referencias
        @problemas = Ti::Problema.where.not(legacy_id: nil).includes(:campos).index_by(&:legacy_id)
        @funcoes = Legado::Api.funcoes.to_h { |item| [ item[:id], item[:nome] ] }
        @cargos = Legado::Api.cargos.to_h { |item| [ item[:id], item[:nome] ] }
        @campos = {} # [problema_id, rótulo] => campo
      end

      def importar_lote(lote)
        ids = lote.pluck(:id)
        feitos = Ti::Chamado.where(legacy_id: ids).pluck(:legacy_id).to_set
        usuarios = ::User.where(id: lote.flat_map { |antigo| [ antigo[:user_id], antigo[:tecnico_id] ] }.compact.uniq).index_by(&:id)
        unidades = lote.pluck(:unidade_id).compact.uniq.index_with { |id| Rh::Api.unidade_do_legado(id) }
        mensagens = Legado::Api.mensagens_das_requisicoes_de_ti(ids)
        anexos = Legado::Api.anexos("RequisicaoTi", ids)
        livres = ids.to_set - Ti::Chamado.where(id: ids).pluck(:id)

        lote.each do |antigo|
          next @contagem[:ja_existiam] += 1 if feitos.include?(antigo[:id])

          Ti::Chamado.transaction do
            importar(antigo, usuarios, unidades[antigo[:unidade_id]], mensagens.fetch(antigo[:id], []), anexos.fetch(antigo[:id], []), livres.include?(antigo[:id]))
          end
        end
      end

      def importar(antigo, usuarios, unidade, mensagens, anexos, id_livre)
        problema = @problemas[antigo[:problema_ti_id]]
        solicitante = usuarios[antigo[:user_id]]
        return @ignorados << "#{antigo[:id]}: #{problema ? 'solicitante' : 'solicitação'} não existe no sistema novo" unless problema && solicitante

        tecnico = usuarios[antigo[:tecnico_id]]
        chamado = criar_chamado(antigo, problema, solicitante, tecnico, unidade, id_livre)
        @contagem[:valores] += gravar_valores(chamado, problema, antigo, anexos)
        gravar_eventos(chamado, antigo, solicitante, tecnico)
        @contagem[:mensagens] += importar_conversa(chamado, solicitante, tecnico, mensagens, usuarios)
        @contagem[:importados] += 1
      end

      def criar_chamado(antigo, problema, solicitante, tecnico, unidade, id_livre)
        status = STATUS.fetch(antigo[:status], "cancelado")
        chamado = Ti::Chamado.new(
          legacy_id: antigo[:id], problema: problema, status: status, prioridade: problema.prioridade_padrao, solicitante: solicitante,
          solicitante_nome: solicitante.nome.presence || solicitante.email, solicitante_email: solicitante.email, rh_unidade_id: unidade&.id,
          unidade_nome: unidade&.sigla_e_nome, funcao_nome: @funcoes[antigo[:funcao_id]], responsavel: tecnico, aberto_em: antigo[:created_at],
          concluido_em: antigo[:data_hora_concluida], finalizado_em: antigo[:data_hora_finalizada], avaliacao: antigo[:avaliacao],
          avaliacao_comentario: antigo[:comentario].presence, created_at: antigo[:created_at], updated_at: antigo[:updated_at]
        )
        chamado.id = antigo[:id] if id_livre # TI-000123 para o chamado antigo 123
        chamado.save!
        chamado
      end

      # Os campos soltos do chamado antigo viram "dados informados", no campo de mesmo nome do formulário da
      # solicitação. Se a solicitação não tem esse campo, ele é criado inativo (não aparece para quem abre chamado).
      def gravar_valores(chamado, problema, antigo, anexos)
        feitos = CAMPOS.count do |coluna, (rotulo, tipo)|
          texto = texto_de(coluna, antigo[coluna])
          next false if texto.blank?

          campo = campo_de(problema, rotulo, tipo)
          chamado.valores.create!(campo_problema_id: campo.id, rotulo: campo.rotulo, tipo: campo.tipo, valor_texto: texto, valor_json: json_de(campo, texto),
                                  created_at: antigo[:created_at], updated_at: antigo[:created_at])
        end
        feitos + anexos.group_by { |anexo| ANEXOS[anexo[:nome]] }.count do |rotulo, arquivos|
          next false unless rotulo

          campo = campo_de(problema, rotulo, "arquivo")
          valor = chamado.valores.create!(campo_problema_id: campo.id, rotulo: campo.rotulo, tipo: campo.tipo, valor_texto: "", created_at: antigo[:created_at], updated_at: antigo[:created_at])
          arquivos.each { |arquivo| ActiveStorage::Attachment.create!(name: "arquivos", record: valor, blob_id: arquivo[:blob_id]) } # o mesmo arquivo, sem copiar
          valor.update_columns(valor_texto: valor.arquivos.map { |arquivo| arquivo.filename.to_s }.join(", "))
        end
      end

      def texto_de(coluna, valor)
        case coluna
        when :cargo_id then @cargos[valor]
        when :funcao_id then @funcoes[valor]
        when :data_nascimento, :periodo_inicio, :periodo_fim then valor && DataBr.formatar(valor)
        else valor.to_s.strip
        end
      end

      # Campos de busca guardam também o rótulo escolhido; nos demais o texto basta.
      def json_de(campo, texto) = campo.com_fonte? ? { "rotulo" => texto } : {}

      def campo_de(problema, rotulo, tipo)
        @campos[[ problema.id, rotulo ]] ||= problema.campos.find { |campo| campo.rotulo == rotulo } || begin
          @contagem[:campos] += 1
          problema.campos.create!(rotulo: rotulo, tipo: tipo, status: "inativo", ajuda: AJUDA_DO_CAMPO_ANTIGO)
        end
      end

      # O histórico é remontado com as datas que o siscom antigo guardava.
      def gravar_eventos(chamado, antigo, solicitante, tecnico)
        evento = lambda do |tipo, de, para, nota, ator, em|
          chamado.eventos.create!(tipo: tipo, de_status: de, para_status: para, nota: nota, ator: ator, ator_nome: ator&.nome || "Siscom antigo", ocorrido_em: em || antigo[:updated_at],
                                  created_at: em || antigo[:updated_at], updated_at: em || antigo[:updated_at])
        end
        evento.call("aberto", nil, "aberto", "Chamado aberto pelo solicitante (migrado do siscom antigo, chamado nº #{antigo[:id]}).", solicitante, antigo[:created_at])
        if antigo[:data_hora_em_atendimento] && tecnico
          evento.call("assumido", "aberto", "em_atendimento", "Chamado assumido para atendimento por #{tecnico.nome}.", tecnico, antigo[:data_hora_em_atendimento])
        end
        if antigo[:data_hora_concluida]
          evento.call("concluido", "em_atendimento", "concluido", "Atendimento concluído: #{antigo[:solucao].to_s.squish.presence || 'sem descrição da solução.'}", tecnico, antigo[:data_hora_concluida])
        end
        if chamado.finalizado?
          nota = "Chamado finalizado pelo solicitante. Avaliação: #{AVALIACOES[antigo[:avaliacao]] || 'não informada'}."
          evento.call("finalizado", "concluido", "finalizado", [ nota, antigo[:comentario].to_s.squish.presence ].compact.join(" "), solicitante, antigo[:data_hora_finalizada])
        elsif chamado.cancelado?
          evento.call("cancelado", nil, "cancelado", "Chamado cancelado no siscom antigo.", nil, antigo[:updated_at])
        end
      end

      # As mensagens antigas viram a conversa do chamado. Depois, a regra normal decide se ela continua aberta
      # (chamado ainda em atendimento) ou fica só para consulta.
      def importar_conversa(chamado, solicitante, tecnico, mensagens, usuarios)
        return 0 if mensagens.empty?

        autores = ::User.where(id: mensagens.pluck(:user_id).uniq - usuarios.keys).index_by(&:id).merge(usuarios)
        imagens = Legado::Api.anexos("Mensagem", mensagens.pluck(:id))
        rotas = Rails.application.routes.url_helpers
        Core::Api.importar_conversa(
          alvo: chamado, modulo: :ti, titulo: "#{chamado.codigo} · #{chamado.problema.nome}", motivo_leitura: ENCERRADA,
          participantes: [ { user: solicitante, papel: "solicitante", url: rotas.ti_chamado_path(chamado) }, { user: tecnico, papel: "tecnico", url: rotas.ti_operacao_path(chamado) } ],
          mensagens: mensagens.map do |mensagem|
            { autor: autores[mensagem[:user_id]], em: mensagem[:created_at],
              corpo: [ mensagem[:texto].to_s.strip.presence, ("[Havia uma imagem anexada no siscom antigo.]" if imagens.key?(mensagem[:id])) ].compact.join("\n") }
          end
        )
        Ti::Chamados::Conversa.sincronizar(chamado) if chamado.em_andamento?
        mensagens.size
      end

      # Depois de gravar com os ids antigos, o próximo chamado novo continua a numeração.
      def acertar_sequencia
        Ti::Chamado.connection.execute("SELECT setval(pg_get_serial_sequence('ti_chamados', 'id'), GREATEST((SELECT COALESCE(MAX(id), 0) FROM ti_chamados), 1))")
      end
    end
  end
end
