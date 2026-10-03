module Rh
  module Pessoas
    # Cadastra ou atualiza uma pessoa (porta de hr/people/create_service, update_service e
    # user_sync_service): toda pessoa fica ligada a uma conta do sistema — a conta é criada
    # na hora (senha temporária em `pessoa.senha_temporaria`) ou, se já existe uma conta com
    # o mesmo e-mail e sem pessoa, é aproveitada. Nome e e-mail da conta acompanham a pessoa.
    class Salvar
      PERMISSAO = "rh.pessoas.gerenciar".freeze
      CAMPOS = %i[nome email celular cpf data_nascimento sexo].freeze
      CAMPOS_DO_VINCULO = %i[tipo_vinculo_id cargo_id data_inicio].freeze

      def self.call(...) = new(...).call

      def initialize(pessoa:, atributos:, salvo_por:)
        @pessoa = pessoa
        dados = atributos.to_h.deep_symbolize_keys
        @atributos = dados.slice(*CAMPOS)
        @vinculo = (dados[:vinculo] || {}).slice(*CAMPOS_DO_VINCULO)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode cadastrar ou editar pessoas.", objeto: @pessoa)
        end

        nova = @pessoa.new_record?
        @pessoa.assign_attributes(@atributos)
        montar_vinculo
        return Core::Resultado.falha(@pessoa) unless validar

        salvou = Rh::Pessoa.transaction do
          ligar_conta || raise(ActiveRecord::Rollback)
          @pessoa.save!
          true
        end
        return Core::Resultado.falha(@pessoa) unless salvou

        registrar(nova)
        Core::Resultado.sucesso(@pessoa)
      end

      private

      # Vínculo funcional é um grupo opcional: se algum campo for preenchido, todos são obrigatórios.
      def montar_vinculo
        if @vinculo.values.all?(&:blank?)
          @pessoa.vinculo&.mark_for_destruction if @vinculo.any?
          return
        end

        vinculo = @pessoa.vinculo || @pessoa.build_vinculo
        vinculo.assign_attributes(@vinculo)
      end

      # No cadastro pela tela, celular e CPF são obrigatórios (regra do seed); pessoas importadas
      # sem CPF continuam válidas até alguém corrigir.
      def conferir_dados_obrigatorios
        @pessoa.errors.add(:celular, :blank) if @pessoa.celular.blank?
        @pessoa.errors.add(:cpf, :blank) if @pessoa.cpf.blank? && (@pessoa.new_record? || @pessoa.cpf_in_database.present?)
      end

      # Validações do model + os obrigatórios da tela, todos de uma vez.
      def validar
        @pessoa.valid?
        conferir_dados_obrigatorios
        @pessoa.errors.empty?
      end

      def ligar_conta
        conta = @pessoa.user || Core::Api.conta_por_email(@pessoa.email)

        if conta.nil?
          resultado = Core::Api.criar_conta(nome: @pessoa.nome, email: @pessoa.email, criado_por: @salvo_por)
          return falha_da_conta(resultado) if resultado.falha?

          @pessoa.user = resultado.objeto
          @pessoa.senha_temporaria = resultado.objeto.senha_temporaria
        elsif @pessoa.user.nil?
          if Rh::Pessoa.exists?(user_id: conta.id)
            @pessoa.errors.add(:email, "já pertence à conta de outra pessoa")
            return false
          end
          @pessoa.user = conta
        end

        resultado = Core::Api.sincronizar_conta(@pessoa.user, nome: @pessoa.nome, email: @pessoa.email, atualizado_por: @salvo_por)
        resultado.sucesso? || falha_da_conta(resultado)
      end

      def falha_da_conta(resultado)
        resultado.erros.each { |mensagem| @pessoa.errors.add(:base, "Conta de acesso: #{mensagem}") }
        false
      end

      def registrar(nova)
        mudancas = @pessoa.saved_changes.except("created_at", "updated_at", "id", "user_id")
                          .transform_values { |de, para| { de: de, para: para } }
        return if mudancas.empty? && !nova

        Core::Api.auditar(evento: "rh.pessoa.#{nova ? 'criada' : 'atualizada'}", alvo: @pessoa, ator: @salvo_por,
                          dados: (nova ? { email: @pessoa.email, conta_nova: @pessoa.senha_temporaria.present? } : { mudancas: mudancas }))
      end
    end
  end
end
