module Core
  # Regras para senhas novas: tamanho mínimo (Devise), nunca a senha padrão
  # antiga do siscom e sem repetir a atual nem as últimas anteriores.
  class PoliticaDeSenha
    HISTORICO = 5
    PADRAO_ANTIGA = "seed@123".freeze

    def self.padrao_antiga?(senha) = senha.to_s.strip.downcase == PADRAO_ANTIGA

    # Senha temporária para redefinição: fácil de ditar, sem caracteres ambíguos.
    def self.gerar_temporaria
      alfabeto = %w[A B C D E F G H J K L M N P Q R S T U V W X Y Z a b c d e f g h j k m n p q r s t u v w x y z 2 3 4 5 6 7 8 9]
      Array.new(12) { alfabeto[SecureRandom.random_number(alfabeto.size)] }.join
    end

    def initialize(user)
      @user = user
    end

    # Mensagens de erro para a senha nova (vazio = aceita).
    def erros(senha)
      return [ "não pode ser a senha padrão antiga" ] if self.class.padrao_antiga?(senha)
      return [ "não pode repetir uma das últimas #{HISTORICO} senhas" ] if reutilizada?(senha)

      []
    end

    private

    def reutilizada?(senha)
      hashes = [ @user.encrypted_password_in_database ] +
               @user.senhas_anteriores.order(created_at: :desc).limit(HISTORICO - 1).pluck(:senha_criptografada)

      hashes.compact_blank.any? { |hash| Devise::Encryptor.compare(@user.class, hash, senha) }
    end
  end
end
