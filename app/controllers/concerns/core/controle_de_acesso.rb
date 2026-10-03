module Core
  # Autorização nos controllers e views: `pode?`, `pode!`, `autorizacao` e a
  # resposta 403 para Core::AcessoNegado e Pundit::NotAuthorizedError.
  module ControleDeAcesso
    extend ActiveSupport::Concern

    included do
      include Pundit::Authorization

      helper_method :autorizacao, :pode?

      rescue_from Core::AcessoNegado, Pundit::NotAuthorizedError, with: :acesso_negado
    end

    def autorizacao
      @autorizacao ||= Core::Autorizacao.new(current_user)
    end

    def pode?(permissao, escopo: nil) = autorizacao.pode?(permissao, escopo: escopo)

    def pode!(permissao, escopo: nil) = autorizacao.pode!(permissao, escopo: escopo)

    private

    def acesso_negado
      respond_to do |format|
        format.html { render "erros/acesso_negado", status: :forbidden }
        format.turbo_stream { head :forbidden }
        format.any { head :forbidden }
      end
    end
  end
end
