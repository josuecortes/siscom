module Rh
  # RH → Lotações (porta de hr-assignments-module.tsx): quem está lotado onde.
  class LotacoesController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.lotacoes.ver") }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo todos]) || "ativo" }
      lotacoes = Rh::Lotacao.joins(:pessoa, :unidade).includes(:pessoa, :unidade, :funcao).order("rh_pessoas.nome", data_inicio: :desc)
      lotacoes = lotacoes.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      if @filtros[:q].present?
        padrao = "%#{Rh::Lotacao.sanitize_sql_like(@filtros[:q].squish.upcase)}%"
        lotacoes = lotacoes.where("rh_pessoas.nome LIKE :p OR rh_unidades.nome LIKE :p OR rh_unidades.sigla LIKE :p", p: padrao)
      end
      @pagy, @lotacoes = pagy(:offset, lotacoes, limit: POR_PAGINA)
    end

    # Nova lotação pela lista: a pessoa também é escolhida por busca.
    def new
      pode!(Rh::Lotacoes::Lotar::PERMISSAO)
      @lotacao = Rh::Lotacao.new(data_inicio: Date.current)
    end

    # Bloco "Lotações ativas da pessoa" do painel, carregado ao escolher a pessoa.
    def ativas
      pode!(Rh::Lotacoes::Lotar::PERMISSAO)
      @pessoa = Rh::Pessoa.find_by(id: params[:pessoa_id])
    end

    def create
      pode!(Rh::Lotacoes::Lotar::PERMISSAO)
      atributos = params.expect(lotacao: %i[pessoa_id unidade_id funcao_id data_inicio])
      resultado = Rh::Lotacoes::Lotar.call(pessoa: Rh::Pessoa.find_by(id: atributos[:pessoa_id]), atributos: atributos, lotado_por: current_user)
      @lotacao = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: "Lotação registrada com sucesso.", voltar_para: rh_lotacoes_path)
      else
        render :new, status: :unprocessable_content
      end
    end

    def encerrar
      lotacao = Rh::Lotacao.find(params[:id])
      resultado = Rh::Lotacoes::Encerrar.call(lotacao: lotacao, encerrado_por: current_user)
      raise Core::AcessoNegado, Rh::Lotacoes::Lotar::PERMISSAO if resultado.falha? && !pode?(Rh::Lotacoes::Lotar::PERMISSAO)

      opcoes = resultado.sucesso? ? { notice: "Lotação encerrada." } : { alert: resultado.mensagem_de_erro }
      redirect_back_or_to rh_lotacoes_path, status: :see_other, **opcoes
    end
  end
end
