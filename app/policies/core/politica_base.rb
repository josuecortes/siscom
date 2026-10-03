module Core
  # Base das policies (Pundit) de todos os módulos. As regras consultam o
  # catálogo de permissões em vez de papéis fixos:
  #
  #   class Rh::PessoaPolicy < Core::PoliticaBase
  #     def update? = permissao?("rh.pessoas.editar", escopo: record.unidade_escopo)
  #
  #     class Scope < Scope
  #       def resolve = limitar("rh.pessoas.ver", tipo: "rh_unidade", coluna: :rh_unidade_id)
  #     end
  #   end
  class PoliticaBase
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    # Nada é permitido por padrão.
    def index? = false
    def show? = false
    def create? = false
    def new? = create?
    def update? = false
    def edit? = update?
    def destroy? = false

    private

    def autorizacao
      @autorizacao ||= Core::Autorizacao.new(user)
    end

    def permissao?(permissao, escopo: nil) = autorizacao.pode?(permissao, escopo: escopo)

    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve = scope.none

      private

      def autorizacao
        @autorizacao ||= Core::Autorizacao.new(user)
      end

      # Tudo, nada ou só os registros dos escopos em que a permissão vale.
      def limitar(permissao, tipo:, coluna:)
        abrangencia = autorizacao.escopos(permissao)
        return scope.all if abrangencia == Core::Autorizacao::TODOS

        ids = abrangencia.select { |escopo_tipo, _| escopo_tipo == tipo.to_s }.map(&:last)
        scope.where(coluna => ids)
      end
    end
  end
end
