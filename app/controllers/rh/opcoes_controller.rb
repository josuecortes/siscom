module Rh
  # Opções para os campos de busca (autocomplete) dos formulários do RH, em JSON.
  # Regra: com 3 letras ou mais, o que combina com o texto; se nada combinar (ou com
  # menos de 3 letras), a lista em ordem alfabética.
  class OpcoesController < BaseController
    LIMITE = 50
    MINIMO = 3
    PERMISSOES = %w[rh.pessoas.gerenciar rh.unidades.gerenciar rh.lotacoes.gerenciar].freeze

    before_action { raise Core::AcessoNegado unless PERMISSOES.any? { |permissao| pode?(permissao) } }

    def index
      relacao, montar = fonte(params[:fonte])
      termo = params[:q].to_s.squish
      filtrada = termo.length >= MINIMO ? relacao.buscar(termo) : nil
      todas = filtrada.nil? || filtrada.none?
      escolhida = todas ? relacao : filtrada
      total = escolhida.count

      render json: { opcoes: escolhida.limit(LIMITE).map(&montar), todas: todas, restantes: [ total - LIMITE, 0 ].max }
    end

    private

    def fonte(nome)
      simples = ->(registro) { { valor: registro.id, rotulo: registro.nome } }

      case nome
      when "tipos_vinculo" then [ Rh::TipoVinculo.ativo.ordenados, simples ]
      when "cargos" then [ Rh::Cargo.ativo.ordenados, simples ]
      when "funcoes" then [ Rh::Funcao.ativo.ordenados, simples ]
      when "unidades"
        [ Rh::Unidade.ativo.where.not(id: params[:exceto].presence).ordenadas,
          ->(unidade) { { valor: unidade.id, rotulo: unidade.sigla_e_nome, subtitulo: nil } } ]
      when "pessoas"
        [ Rh::Pessoa.ordenadas, ->(pessoa) { { valor: pessoa.id, rotulo: pessoa.nome, subtitulo: pessoa.email } } ]
      else raise ActiveRecord::RecordNotFound
      end
    end
  end
end
