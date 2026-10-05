module Transporte
  module Solicitacoes
    # Abre uma solicitação de transporte (porta de requests/create_service.rb do seed): confere a
    # permissão, a lotação escolhida, a janela de antecedência da saída e as faixas de horas do modo
    # de serviço (Configuração do módulo), o retorno e o documento da viagem, passageiros e destinos.
    #
    # Com `aberto_por` (operação), a solicitação fica em nome de `user`; com `fora_do_padrao`, a
    # operação abre fora da janela de antecedência (é o "fora do padrão" do seed; não há "urgente").
    #
    # Em falha, `objeto` é a solicitação (não gravada) com os erros; os de passageiros e destinos
    # ficam em cada um deles.
    class Abrir
      PERMISSAO = "transporte.solicitacoes.abrir".freeze
      PERMISSAO_DA_OPERACAO = "transporte.solicitacoes.operar".freeze
      CAMPOS = %i[tipo modo resumo saida_em retorno_em espera_horas busca_horas lotacao_id documento_da_viagem].freeze
      CAMPOS_DO_PASSAGEIRO = %i[cpf nome].freeze
      CAMPOS_DO_DESTINO = %i[nome cep logradouro numero bairro cidade uf latitude longitude].freeze

      def self.call(...) = new(...).call

      # "dd/mm/aaaa hh:mm" (ou um Time) no fuso do sistema; nil quando não dá para entender.
      def self.data_e_hora(valor)
        return valor.in_time_zone if valor.respond_to?(:in_time_zone) && !valor.is_a?(String)

        Time.zone.strptime(valor.to_s.strip, "%d/%m/%Y %H:%M")
      rescue ArgumentError
        nil
      end

      def initialize(user:, atributos:, aberto_por: nil, fora_do_padrao: false)
        @user = user
        @aberto_por = aberto_por unless aberto_por == user
        @fora_do_padrao = fora_do_padrao && @aberto_por.present?
        @dados = atributos.to_h.deep_symbolize_keys
      end

      def call
        @solicitacao = montar
        return falha(:base, "Escolha para quem é a solicitação.") unless @user&.ativo?
        return falha(:base, "Você não pode abrir solicitações de transporte.") unless autorizado?

        conferir_lotacao
        conferir_datas
        conferir_modo
        conferir_documento
        conferir_listas
        return Core::Resultado.falha(@solicitacao.errors.full_messages.presence || "Revise os campos destacados.", objeto: @solicitacao) if erros?

        gravar
        avisar
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def autorizado?
        return Core::Autorizacao.new(@aberto_por).pode?(PERMISSAO_DA_OPERACAO) if @aberto_por

        Core::Autorizacao.new(@user).pode?(PERMISSAO)
      end

      def montar
        solicitacao = Transporte::Solicitacao.new(
          tipo: @dados[:tipo].presence || "normal", modo: @dados[:modo].presence, resumo: @dados[:resumo],
          saida_em: self.class.data_e_hora(@dados[:saida_em]), solicitante: @user, solicitante_nome: @user&.nome, solicitante_email: @user&.email,
          aberto_por: @aberto_por, fora_do_padrao: @fora_do_padrao
        )
        solicitacao.retorno_em = self.class.data_e_hora(@dados[:retorno_em]) if solicitacao.viagem?
        solicitacao.espera_horas = @dados[:espera_horas].presence if solicitacao.esperar_no_local?
        solicitacao.busca_horas = @dados[:busca_horas].presence if solicitacao.buscar_depois?
        lista(@dados[:passageiros]).each_with_index { |item, posicao| solicitacao.passageiros.build(item.slice(*CAMPOS_DO_PASSAGEIRO).merge(posicao: posicao)) }
        lista(@dados[:destinos]).each_with_index { |item, posicao| solicitacao.destinos.build(item.slice(*CAMPOS_DO_DESTINO).merge(posicao: posicao)) }
        solicitacao
      end

      # Os itens vêm do formulário como { "0" => {...}, "1" => {...} } (ou uma lista); linhas em branco são ignoradas.
      def lista(valor)
        itens = valor.is_a?(Hash) ? valor.sort_by { |chave, _| chave.to_s.to_i }.map(&:last) : Array(valor)
        itens.select { |item| item.is_a?(Hash) && item.except(:latitude, :longitude).values.any?(&:present?) }
      end

      def conferir_lotacao
        lotacoes = Rh::Api.lotacoes_ativas(@user)
        lotacao = lotacoes.size <= 1 ? lotacoes.first : lotacoes.find { |item| item.id == @dados[:lotacao_id].to_i }
        return @solicitacao.errors.add(:lotacao_id, "deve ser escolhida") if lotacoes.size > 1 && lotacao.nil?
        return unless lotacao

        @solicitacao.assign_attributes(rh_unidade_id: lotacao.unidade.id, unidade_nome: [ lotacao.unidade.sigla, lotacao.unidade.nome ].compact_blank.join(" - "))
      end

      def conferir_datas
        saida = @solicitacao.saida_em
        return @solicitacao.errors.add(:saida_em, "deve ser uma data e hora válidas (dd/mm/aaaa hh:mm)") if saida.nil?
        @solicitacao.errors.add(:retorno_em, "deve ser uma data e hora válidas (dd/mm/aaaa hh:mm)") if @solicitacao.viagem? && @solicitacao.retorno_em.nil?
        return @solicitacao.errors.add(:saida_em, "não pode estar no passado") if saida < Time.current
        return if @fora_do_padrao

        prefixo = @solicitacao.viagem? ? "viagem" : "normal"
        agora = Time.current.change(sec: 0)
        minimo = agora + configuracao[:"#{prefixo}_antecedencia_min_horas"].hours
        maximo = agora + configuracao[:"#{prefixo}_antecedencia_max_horas"].hours
        return if saida.between?(minimo, maximo)

        @solicitacao.errors.add(:saida_em, "está fora do prazo para pedir: deve ficar entre #{I18n.l(minimo, format: '%d/%m/%Y %H:%M')} e " \
                                           "#{I18n.l(maximo, format: '%d/%m/%Y %H:%M')}. Fora disso, procure o setor de transporte.")
      end

      def conferir_modo
        { esperar_no_local: [ :espera_horas, "espera" ], buscar_depois: [ :busca_horas, "busca" ] }.each do |modo, (campo, faixa)|
          next unless @solicitacao.modo == modo.to_s

          horas = Integer(@solicitacao[campo].to_s, exception: false)
          minimo, maximo = configuracao[:"#{faixa}_min_horas"], configuracao[:"#{faixa}_max_horas"]
          next @solicitacao.errors.add(campo, "deve ser informado em horas") if horas.nil?
          next if @fora_do_padrao || horas.between?(minimo, maximo)

          @solicitacao.errors.add(campo, "deve ficar entre #{minimo} e #{maximo} hora(s)")
        end
      end

      def conferir_documento
        return unless @solicitacao.viagem?

        arquivo = @dados[:documento_da_viagem]
        return @solicitacao.errors.add(:documento_da_viagem, "deve ser anexado para viagem") unless arquivo.respond_to?(:original_filename)
        return @solicitacao.errors.add(:documento_da_viagem, "deve ter no máximo 10 MB") if arquivo.size > 10.megabytes

        @solicitacao.documento_da_viagem.attach(arquivo)
      end

      def conferir_listas
        @solicitacao.errors.add(:passageiros, "deve ter pelo menos um") if @solicitacao.passageiros.empty?
        @solicitacao.errors.add(:destinos, "deve ter pelo menos um") if @solicitacao.destinos.empty?
        cpfs = @solicitacao.passageiros.map(&:cpf)
        @solicitacao.errors.add(:passageiros, "não pode repetir o mesmo CPF") if cpfs.uniq.size < cpfs.size
        (@solicitacao.passageiros + @solicitacao.destinos).each(&:validate)
      end

      def erros?
        erros_de_base = @solicitacao.errors.dup
        @solicitacao.validate
        erros_de_base.each { |erro| @solicitacao.errors.add(erro.attribute, erro.message) unless @solicitacao.errors.added?(erro.attribute, erro.message) }
        # `validate` roda de novo os filhos: os erros deles ficam em cada passageiro/destino.
        @solicitacao.errors.delete(:passageiros) if @solicitacao.passageiros.any? && @solicitacao.errors[:passageiros].all? { |m| m == "não é válido" }
        @solicitacao.errors.any? || (@solicitacao.passageiros + @solicitacao.destinos).any? { |item| item.errors.any? }
      end

      def gravar
        Transporte::Solicitacao.transaction do
          @solicitacao.save!
          ator = @aberto_por || @user
          Core::Api.auditar(evento: "transporte.solicitacao.aberta", alvo: @solicitacao, ator: ator,
                            dados: { codigo: @solicitacao.codigo, tipo: @solicitacao.tipo, fora_do_padrao: @fora_do_padrao.presence,
                                     em_nome_de: (@user.id if @aberto_por) }.compact)
        end
      end

      # Quem aprova (técnicos e administradores do transporte) fica sabendo do pedido novo.
      def avisar
        ator = @aberto_por || @user
        operacao = ::User.ativos.where(id: Core::Api.ids_dos_usuarios_com_papel(modulo: :transporte, papeis: %w[admin tecnico]))
        Core::Api.notificar(destinatarios: operacao, evento: "transporte.solicitacao.aberta", titulo: "Nova solicitação de transporte",
                            mensagem: "#{@solicitacao.codigo} - saída em #{I18n.l(@solicitacao.saida_em, format: '%d/%m/%Y %H:%M')}", alvo: @solicitacao, ator: ator)
        return unless @aberto_por

        Core::Api.notificar(destinatarios: [ @user ], evento: "transporte.solicitacao.aberta_em_seu_nome", titulo: "Solicitação de transporte aberta em seu nome",
                            mensagem: "#{@aberto_por.nome} abriu a solicitação #{@solicitacao.codigo} para você.", alvo: @solicitacao, ator: @aberto_por)
      end

      def configuracao = @configuracao ||= Transporte::Configuracao.atual

      def falha(campo, mensagem)
        @solicitacao.errors.add(campo, mensagem)
        Core::Resultado.falha(mensagem, objeto: @solicitacao)
      end
    end
  end
end
