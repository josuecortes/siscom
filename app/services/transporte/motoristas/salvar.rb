module Transporte
  module Motoristas
    # Cadastra ou atualiza um motorista (porta de drivers/upsert_service.rb do seed). No cadastro,
    # liga à conta que já existe com o e-mail informado ou cria uma (senha temporária, mostrada uma
    # vez em `objeto.senha_temporaria`) e dá a ela a permissão de motorista.
    class Salvar
      PERMISSAO = "transporte.motoristas.gerenciar".freeze
      CAMPOS = %i[nome cpf data_nascimento cnh_numero cnh_categoria cnh_validade].freeze

      def self.call(...) = new(...).call

      def initialize(motorista:, atributos:, salvo_por:)
        @motorista = motorista
        dados = atributos.to_h.symbolize_keys
        @atributos = dados.slice(*CAMPOS)
        @email = dados[:email].to_s.strip.downcase
        @salvo_por = salvo_por
      end

      def call
        return falha("Você não pode cadastrar motoristas.") unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)

        novo = @motorista.new_record?
        @motorista.assign_attributes(@atributos)
        senha = nil
        Transporte::Motorista.transaction do
          senha = ligar_conta if novo
          raise ActiveRecord::Rollback if @motorista.errors.any?
          unless @motorista.save
            @motorista.errors.add(:email, "já pertence a um motorista cadastrado") if @motorista.errors[:user_id].any?
            raise ActiveRecord::Rollback
          end

          dar_permissao
          Core::Api.auditar(evento: "transporte.motorista.#{novo ? 'cadastrado' : 'atualizado'}", alvo: @motorista, ator: @salvo_por,
                            dados: { nome: @motorista.nome })
        end
        return Core::Resultado.falha(@motorista) if @motorista.errors.any?

        @motorista.define_singleton_method(:senha_temporaria) { senha }
        Core::Resultado.sucesso(@motorista)
      end

      private

      # Liga o motorista a uma conta. Devolve a senha temporária quando a conta foi criada agora.
      def ligar_conta
        if @email.blank?
          @motorista.errors.add(:email, "não pode ficar em branco")
          return nil
        end

        conta = Core::Api.conta_por_email(@email)
        if conta
          @motorista.user = conta
          return nil
        end

        # Só cria a conta se os dados do motorista estiverem certos (o que falta agora é só a conta).
        @motorista.validate
        @motorista.errors.delete(:user)
        return nil if @motorista.errors.any?

        resultado = Core::Api.criar_conta(nome: @motorista.nome, email: @email, criado_por: @salvo_por)
        if resultado.falha?
          @motorista.errors.add(:email, resultado.mensagem_de_erro)
          return nil
        end
        @motorista.user = resultado.objeto
        resultado.objeto.senha_temporaria
      end

      def dar_permissao
        atuais = Core::Api.papeis_concedidos([ @motorista.user_id ], modulo: :transporte).fetch(@motorista.user_id, [])
        return if atuais.include?("motorista")

        resultado = Core::Api.definir_papeis(user: @motorista.user, modulo: :transporte, papeis: atuais + [ "motorista" ], definido_por: @salvo_por)
        return if resultado.sucesso?

        @motorista.errors.add(:base, resultado.mensagem_de_erro)
        raise ActiveRecord::Rollback
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @motorista)
    end
  end
end
