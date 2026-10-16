module Rh
  # RH → Minha ficha: a própria ficha, só para consulta (papel automático do RH).
  class MinhaFichaController < BaseController
    before_action { pode!("rh.minha_ficha.ver") }

    def show
      @pessoa = Rh::Pessoa.find_by(user_id: current_user.id)
      return unless @pessoa

      @lotacoes = @pessoa.lotacoes.includes(:unidade, :funcao).order(Arel.sql("status = 'ativo' DESC"), data_inicio: :desc, id: :desc)
    end
  end
end
