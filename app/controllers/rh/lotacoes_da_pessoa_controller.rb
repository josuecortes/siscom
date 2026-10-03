module Rh
  # Nova lotação a partir da ficha da pessoa.
  class LotacoesDaPessoaController < BaseController
    before_action { pode!("rh.lotacoes.gerenciar") }
    before_action { @pessoa = Rh::Pessoa.find(params[:pessoa_id]) }

    def new
      @lotacao = Rh::Lotacao.new(pessoa: @pessoa, data_inicio: Date.current)
    end

    def create
      resultado = Rh::Lotacoes::Lotar.call(pessoa: @pessoa, atributos: params.expect(lotacao: %i[unidade_id funcao_id data_inicio]),
                                           lotado_por: current_user)
      @lotacao = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: "Lotação registrada com sucesso.", voltar_para: rh_pessoa_path(@pessoa))
      else
        render :new, status: :unprocessable_content
      end
    end
  end
end
