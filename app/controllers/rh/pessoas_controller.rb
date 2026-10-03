module Rh
  # RH → Pessoas (porta de hr-people-module.tsx): lista, ficha, cadastro e edição.
  class PessoasController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.pessoas.ver") }
    before_action(only: %i[new create edit update]) { pode!("rh.pessoas.gerenciar") }
    before_action :carregar_pessoa, only: %i[show edit update]

    def index
      @filtros = { q: params[:q].to_s.strip, situacao: params[:situacao].presence_in(%w[com_pendencia sem_lotacao]) || "todas" }
      pessoas = Rh::Pessoa.ordenadas.includes(:user)
      pessoas = pessoas.buscar(@filtros[:q]) if @filtros[:q].present?
      pessoas = pessoas.where(id: Rh::PendenciaImportacao.abertas.select(:pessoa_id)) if @filtros[:situacao] == "com_pendencia"
      pessoas = pessoas.where.not(id: Rh::Lotacao.ativo.select(:pessoa_id)) if @filtros[:situacao] == "sem_lotacao"

      @pagy, @pessoas = pagy(:offset, pessoas, limit: POR_PAGINA)
      ids = @pessoas.map(&:id)
      @lotacoes = Rh::Lotacao.ativo.where(pessoa_id: ids).includes(:unidade, :funcao).recentes.group_by(&:pessoa_id)
      @pendencias = Rh::PendenciaImportacao.abertas.where(pessoa_id: ids).group(:pessoa_id).count
    end

    def show
      carregar_ficha(@pessoa)
    end

    def new
      @pessoa = Rh::Pessoa.new
    end

    def create
      resultado = Rh::Pessoas::Salvar.call(pessoa: Rh::Pessoa.new, atributos: atributos, salvo_por: current_user)
      @pessoa = resultado.objeto

      if resultado.falha?
        render :new, status: :unprocessable_content
      elsif @pessoa.senha_temporaria.present?
        response.headers["Cache-Control"] = "no-store"
        render :conta_criada
      else
        concluir_painel(aviso: "Pessoa cadastrada e ligada à conta que já existia com este e-mail.", voltar_para: rh_pessoa_path(@pessoa))
      end
    end

    def edit
    end

    def update
      resultado = Rh::Pessoas::Salvar.call(pessoa: @pessoa, atributos: atributos, salvo_por: current_user)
      @pessoa = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: "Pessoa atualizada com sucesso.", voltar_para: rh_pessoa_path(@pessoa))
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar_pessoa
      @pessoa = Rh::Pessoa.find(params[:id])
    end

    def atributos
      params.expect(pessoa: [ :nome, :email, :celular, :cpf, :data_nascimento, :sexo, { vinculo: %i[tipo_vinculo_id cargo_id data_inicio] } ])
    end

    def carregar_ficha(pessoa)
      @lotacoes = pessoa.lotacoes.includes(:unidade, :funcao).order(Arel.sql("status = 'ativo' DESC"), data_inicio: :desc, id: :desc)
      @pendencias = Rh::PendenciaImportacao.abertas.where(pessoa: pessoa)
    end
  end
end
