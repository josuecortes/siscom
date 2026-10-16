module Core
  # Permissões efetivas de um usuário: união dos papéis concedidos (e dos papéis
  # automáticos do catálogo) em cada módulo a que ele tem acesso.
  #
  #   autorizacao = Core::Autorizacao.new(user)
  #   autorizacao.acesso?(:rh)
  #   autorizacao.pode?("rh.pessoas.editar")                  # em qualquer escopo
  #   autorizacao.pode?("rh.pessoas.editar", escopo: unidade)  # global ou nesse escopo
  #   autorizacao.escopos("rh.pessoas.editar")                 # :todos ou [["rh_unidade", 3], ...]
  class Autorizacao
    TODOS = :todos

    def self.chave_de_cache(user_id) = "core/autorizacao/#{user_id}"

    # Chamado quando um acesso ou concessão do usuário muda.
    def self.esquecer(user_id)
      Rails.cache.delete(chave_de_cache(user_id))
    end

    # Aceita registro (Rh::Unidade => "rh_unidade"), [tipo, id] ou { tipo:, id: }.
    def self.normalizar_escopo(escopo)
      case escopo
      when nil then nil
      when Hash then [ escopo.fetch(:tipo).to_s, escopo.fetch(:id).to_i ]
      when Array then [ escopo.first.to_s, escopo.last.to_i ]
      else [ escopo.class.model_name.singular, escopo.id ]
      end
    end

    def initialize(user, catalogo: Catalogo.atual)
      @user = user
      @catalogo = catalogo
    end

    def acesso?(modulo)
      return false unless usuario_ativo?

      definicao = @catalogo.modulo(modulo)
      return false unless definicao

      case dados[:acessos][definicao.chave]
      when "ativo" then true
      when "inativo" then false
      else definicao.papeis_automaticos.any?
      end
    end

    # Papéis do usuário no módulo (concedidos + automáticos), sem repetição.
    def papeis(modulo)
      return [] unless acesso?(modulo)

      definicao = @catalogo.modulo(modulo)
      concedidos = concessoes_de(definicao.chave).map { |c| c[:papel] }
      (concedidos + definicao.papeis_automaticos.map(&:chave)).uniq
    end

    def papel?(modulo, papel) = papeis(modulo).include?(papel.to_s)

    def pode?(permissao, escopo: nil)
      abrangencia = escopos(permissao)
      return false if abrangencia.empty?
      return true if abrangencia == TODOS || escopo.nil?

      abrangencia.include?(self.class.normalizar_escopo(escopo))
    end

    def pode!(permissao, escopo: nil)
      pode?(permissao, escopo: escopo) || raise(AcessoNegado, permissao)
    end

    # Onde a permissão vale: TODOS (algum papel global a concede), uma lista de
    # escopos [tipo, id] ou [] (não tem a permissão).
    def escopos(permissao)
      chave_modulo, local = @catalogo.separar(permissao)
      definicao = @catalogo.modulo(chave_modulo)
      raise ArgumentError, "permissão fora do catálogo: #{permissao}" unless definicao&.permissao?(local)
      return [] unless acesso?(chave_modulo)
      return TODOS if definicao.papeis_automaticos.any? { |papel| papel.permissoes.include?(local) }

      validas = concessoes_de(chave_modulo).select { |c| definicao.permissoes_do_papel(c[:papel]).include?(local) }
      return TODOS if validas.any? { |c| c[:escopo].nil? }

      validas.map { |c| c[:escopo] }.uniq
    end

    # Chaves completas de todas as permissões que o usuário tem em algum escopo.
    def permissoes
      @catalogo.modulos.flat_map do |definicao|
        definicao.permissoes.keys.map { |local| "#{definicao.chave}.#{local}" }
      end.select { |permissao| pode?(permissao) }
    end

    private

    def usuario_ativo?
      @user.present? && @user.ativo?
    end

    def concessoes_de(chave_modulo)
      dados[:concessoes].fetch(chave_modulo, [])
    end

    # { acessos: { "rh" => "ativo" }, concessoes: { "rh" => [{ papel:, escopo: }] } }
    def dados
      @dados ||= Rails.cache.fetch(self.class.chave_de_cache(@user.id)) { carregar }
    end

    def carregar
      {
        acessos: Acesso.where(user_id: @user.id).pluck(:modulo, :status).to_h,
        concessoes: Concessao.ativo.where(user_id: @user.id)
                             .pluck(:modulo, :papel, :escopo_tipo, :escopo_id)
                             .group_by(&:first)
                             .transform_values do |linhas|
                               linhas.map { |_, papel, tipo, id| { papel: papel, escopo: (id ? [ tipo, id ] : nil) } }
                             end
      }
    end
  end
end
