require "bcrypt"

# Senha do painel de acompanhamento (TV, sem login) guardada na configuração do módulo, na coluna
# `senha_do_painel_digest`: só o resumo (BCrypt). Em branco, mantém a atual; sem senha, o painel fica desligado.
module SenhaDoPainel
  extend ActiveSupport::Concern

  included do
    validate { errors.add(:senha_do_painel, "deve ter pelo menos 6 caracteres") if @senha_do_painel && @senha_do_painel.length < 6 }
  end

  def senha_do_painel = nil # nunca volta para a tela

  def senha_do_painel=(senha)
    senha = senha.to_s.strip
    @senha_do_painel = senha.presence
    self.senha_do_painel_digest = BCrypt::Password.create(senha) if senha.length >= 6
  end

  def painel_ligado? = senha_do_painel_digest.present?

  def senha_do_painel_confere?(senha)
    painel_ligado? && BCrypt::Password.new(senha_do_painel_digest).is_password?(senha.to_s)
  end
end
