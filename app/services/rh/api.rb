module Rh
  # Porta de entrada do RH para os outros módulos. Devolve dados simples
  # (Unidade/Lotacao abaixo), nunca os models do RH.
  module Api
    Unidade = Data.define(:id, :nome, :sigla) do
      def sigla_e_nome = [ sigla, nome ].compact.join(" - ")
    end
    Lotacao = Data.define(:id, :unidade, :funcao, :data_inicio)

    module_function

    # Lotações ativas da conta, da mais recente para a mais antiga.
    def lotacoes_ativas(user)
      return [] unless user

      Rh::Lotacao.ativo.joins(:pessoa).where(rh_pessoas: { user_id: user.id }).includes(:unidade, :funcao).recentes.map do |lotacao|
        Lotacao.new(id: lotacao.id, unidade: unidade_de(lotacao.unidade), funcao: lotacao.funcao.nome, data_inicio: lotacao.data_inicio)
      end
    end

    def lotacao_atual(user) = lotacoes_ativas(user).first

    def unidade_atual(user) = lotacao_atual(user)&.unidade

    def unidade(id)
      registro = Rh::Unidade.find_by(id: id)
      registro && unidade_de(registro)
    end

    def buscar_unidades(termo, limite: 20)
      Rh::Unidade.ativo.buscar(termo).ordenadas.limit(limite.to_i.clamp(1, 50)).map { |registro| unidade_de(registro) }
    end

    # Ids das contas (users) com lotação ativa na unidade.
    def ids_dos_usuarios_da_unidade(unidade_id)
      Rh::Lotacao.ativo.where(unidade_id: unidade_id).joins(:pessoa).where.not(rh_pessoas: { user_id: nil })
                 .distinct.pluck("rh_pessoas.user_id")
    end

    # Entidades do RH que podem virar fonte de referência (Core::FontesReferencia::Entidades).
    def entidades_publicaveis
      referencia = ->(nome, descricao) do
        { nome: nome, descricao: descricao, campo_rotulo: "nome", campo_valor: "id", campos_busca: %w[nome], campos: %w[id nome] }
      end

      {
        "pessoas" => { nome: "RH > Pessoas", descricao: "Pessoas cadastradas no RH.", campo_rotulo: "nome", campo_valor: "id",
                       campo_subtitulo: "email", campos_busca: %w[nome email], campos: %w[id nome email cpf] },
        "unidades" => { nome: "RH > Unidades", descricao: "Unidades ativas.", campo_rotulo: "nome", campo_valor: "id",
                        campo_subtitulo: "sigla", campos_busca: %w[nome sigla], campos: %w[id nome sigla] },
        "cargos" => referencia.call("RH > Cargos", "Cargos ativos."),
        "funcoes" => referencia.call("RH > Funções", "Funções de lotação ativas."),
        "tipos_vinculo" => referencia.call("RH > Vínculos", "Tipos de vínculo ativos.")
      }
    end

    def registros_da_entidade(entidade)
      case entidade.to_s
      when "pessoas" then Rh::Pessoa.all
      when "unidades" then Rh::Unidade.ativo
      when "cargos" then Rh::Cargo.ativo
      when "funcoes" then Rh::Funcao.ativo
      when "tipos_vinculo" then Rh::TipoVinculo.ativo
      else raise ArgumentError, "entidade desconhecida: #{entidade}"
      end
    end

    def unidade_de(registro) = Unidade.new(id: registro.id, nome: registro.nome, sigla: registro.sigla)
  end
end
