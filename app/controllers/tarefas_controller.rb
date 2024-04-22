class TarefasController < ApplicationController
  before_action :set_tarefa, only: %i[ show edit update destroy ]
  before_action :load_status, only: %i[ new edit create update ]
  before_action :load_tipos, only: %i[ new edit create update ]
  before_action :load_users, only: %i[ new edit create update ]
  before_action :load_etapas, only: %i[ new edit create update ]
  before_action :load_prioridades, only: %i[ new edit create update ]
  skip_before_action :verify_authenticity_token, only: :atualizar_status

  # GET /tarefas or /tarefas.json
  def index
    carregar_tarefas
    
    @nao_iniciadas = @tarefas.com_status(1)
    @em_andamento = @tarefas.com_status(2)
    @impedidas = @tarefas.com_status(3)
    @concluidas = @tarefas.com_status(4)
  end

  # GET /tarefas/1 or /tarefas/1.json
  def show
  end

  # GET /tarefas/new
  def new
    @tarefa = Tarefa.new
  end

  # GET /tarefas/1/edit
  def edit
  end

  # POST /tarefas or /tarefas.json
  def create
    @tarefa = Tarefa.new(tarefa_params)
    
    respond_to do |format|
      if @tarefa.save
        format.html { redirect_to tarefa_url(@tarefa), notice: "Tarefa was successfully created." }
        format.js {}
      else
        format.html { render :new, status: :unprocessable_entity }
        format.js { render :new }
      end
    end
  end

  # PATCH/PUT /tarefas/1 or /tarefas/1.json
  def update
    @status_antigo = @tarefa.status 
    respond_to do |format|
      if @tarefa.update(tarefa_params)
        @status_atual = @tarefa.status
        @erro = false
        @mensagem = "Tarefa ##{@tarefa.id} atualizada."
        format.html { redirect_to tarefa_url(@tarefa), notice: "Tarefa was successfully updated." }
        format.js {}
      else
        @status_atual = @status_antigo
        format.html { render :edit, status: :unprocessable_entity }
        format.js { render :edit }
      end
    end
  end

  # DELETE /tarefas/1 or /tarefas/1.json
  def destroy
    @erro = false
    
    if @tarefa.nil? || (@tarefa.user != current_user && !current_user_has_permission?(@tarefa))
      @erro = true
    end

    unless @erro
      @id = @tarefa.id
      if @tarefa.destroy
        @erro = false
      else
        @erro = true
      end
    end

    respond_to do |format|
      format.html { redirect_to tarefas_url, notice: "Tarefa was successfully destroyed." }
      format.js {}
    end
  end

  def atualizar_status
    @tarefa = Tarefa.find_by_id(params[:tarefa_id]&.delete_prefix('tarefa_')&.to_i)
    if @tarefa.nil? || (@tarefa.user != current_user && !current_user_has_permission?(@tarefa))
      @erro = true
      return false
    end
        
    container_id = params[:container_id]
  
    if @tarefa && container_id
      status = case container_id
               when "container-1" then "Não Iniciada"
               when "container-2" then "Em andamento"
               when "container-3" then "Impedimento"
               when "container-4" then "Concluída"
               else nil
               end
  
      if status && @tarefa.update(status: status)
        passed = true
      end
    end
    
    passed ? (@erro = false) : (@erro = true)
    
    respond_to do |format|
      format.js {}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tarefa
      @tarefa = Tarefa.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tarefa_params
      params.require(:tarefa).permit(:titulo, :descricao, :tipo, :status, :etapa_id, :user_id, :usuario_logado_id, :prazo, :prioridade)
    end

    def load_status
      @status = Tarefa.statuses.keys
    end

    def load_prioridades
      @prioridades = Tarefa.prioridades.keys
    end

    def load_users
      if current_user.has_role?(:ges_tf_un)
        @users = current_user.unidade.users.order(nome: :asc).all.map{ |u| [u.nome_ulitmo_nome_sigla, u.id, {:nome => u.nome_ulitmo_nome_sigla.downcase!}] }
      else
        @users = User.where(id: current_user.id).order(nome: :asc).all.map{ |u| [u.nome_ulitmo_nome_sigla, u.id, {:nome => u.nome_ulitmo_nome_sigla.downcase!}] }
      end
    end

    def load_tipos
      if current_user.has_role?(:ges_acao)
        @tipos = Tarefa.tipos.keys
      else
        @tipos = Tarefa.tipos.keys.reject { |tipo| tipo == "Ação/Etapa" }
      end
    end

    def load_etapas
      if current_user.has_role?(:ges_acao)
        # acao_users = current_user.acao_users.where(nivel: [1, 2])
        # acoes = []
        # acao_users.each do |acao_user|
        #   acoes << acao_user.acao
        # end
        # etapa_ids = []
        # acoes.each do |acao|
        #   acao.etapas.each do |etapa|
        #     etapa_ids << etapa.id
        #   end
        # end
        # @etapas = Etapa.where(id: etapa_ids).order(nome: :asc).all.map{ |e| [e.nome_etapa_nome_acao, e.id, {:nome => e.nome_etapa_nome_acao.downcase!}] }
        
        acoes = current_user.acao_users.includes(:acao).where(nivel: [1, 2]).map(&:acao).compact.uniq
        etapa_ids = Etapa.joins(acao: :acao_users).where(acao_users: { acao_id: acoes.map(&:id) }).pluck(:id).uniq

        @etapas = Etapa.where(id: etapa_ids).order(nome: :asc).map do |etapa|
          nome_etapa_nome_acao = etapa.nome_etapa_nome_acao
          [nome_etapa_nome_acao, etapa.id, { nome: nome_etapa_nome_acao.downcase }]
        end
      else
        @etapas = []
      end
    end

    def carregar_tarefas
      tarefas_do_usuario = Tarefa.do_usuario(current_user)
      tarefas_da_unidade = Tarefa.none
      tarefas_das_etapas = Tarefa.none
    
      # if current_user.has_role?(:ges_tf_un)
        unidade = current_user.unidade
        tarefas_da_unidade = Tarefa.where(user_id: unidade.users.select(:id), tipo: ['Unidade', 2])
      # end
    
      if current_user.has_role?(:ges_acao)
        etapas_ids = current_user.acao_users.where(nivel: [1, 2]).joins(acao: :etapas).pluck('etapas.id').uniq
        tarefas_das_etapas = Tarefa.where(etapa_id: etapas_ids)
      end
      
      @tarefas = tarefas_do_usuario.or(tarefas_da_unidade).or(tarefas_das_etapas).distinct
      return @tarefas
    end

    def current_user_has_permission?(tarefa)
      case tarefa.tipo
      when "Ação/Etapa"
        current_user.has_role?(:ges_acao)
      when "Unidade"
        current_user.has_role?(:ges_tf_un)
      else
        true
      end
    end
    
    
end
