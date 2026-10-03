module ApplicationCable
  # Só usuários autenticados (sessão do Devise) abrem conexão de tempo real.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env["warden"]&.user(:user)
      reject_unauthorized_connection unless current_user&.ativo?
    end
  end
end
