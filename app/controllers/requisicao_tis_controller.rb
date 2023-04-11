class RequisicaoTisController < ApplicationController
  before_action :verify_permission
  before_action :set_requisicao_ti, only: %i[ show edit update destroy finalizar salvar ]  
  before_action :load_problemas, only: %i[ new create edit update ]
  before_action :load_unidades, only: %i[ new create edit update ]
  before_action :load_funcoes, only: %i[ new create edit update ]
  before_action :load_cargos, only: %i[ new create edit update ]
  before_action :load_perfis, only: %i[ new create edit update ]
  before_action :load_municipios, only: %i[ new create edit update ]
  before_action :load_estados, only: %i[ new create edit update ]

  # GET /requisicao_tis or /requisicao_tis.json
  def index
    params[:status] ? @status = params[:status] : @status = 1
    @requisicao_tis = RequisicaoTi.do_usuario(current_user)
    solicitadas = @requisicao_tis.com_status(1).count
    em_atendimento = @requisicao_tis.com_status(2).count
    concluidas = @requisicao_tis.com_status(3).count
    canceladas = @requisicao_tis.com_status(4).count
    finalizadas = @requisicao_tis.com_status(5).count
    @contagem_requisicoes = [solicitadas, em_atendimento, concluidas, canceladas, finalizadas]
    @requisicao_tis = @requisicao_tis.com_status(@status.to_i)

    requisicoes_finalizadas = RequisicaoTi.finalizar_requisicoes(current_user)
    if requisicoes_finalizadas > 0
      flash[:error] = "O sistema finalizou automaticamente #{requisicoes_finalizadas} #{requisicoes_finalizadas > 1 ? 'requisições que estavam concluídas ' : 'requisição que estava concluída ' } à mais de 3 dias."
    end

    requisicoes_a_finalizar = RequisicaoTi.requisicoes_a_finalizar(current_user)
    if requisicoes_a_finalizar > 0
      flash[:info] = "Você possui  #{requisicoes_a_finalizar} #{requisicoes_a_finalizar > 1 ? 'requisições concluídas ' : 'requisição concluída ' }. As requisições finalizam automaticamente após 3 dias."
    end
  end

  # GET /requisicao_tis/1 or /requisicao_tis/1.json
  def show
  end

  # GET /requisicao_tis/new
  def new
    if current_user.pode_solicitar_requisicao_ti_normal or current_user.pode_solicitar_requisicao_ti
      @requisicao_ti = RequisicaoTi.new
    else
      flash[:error] = "Opss! Você não pode fazer um nova requisição enquanto não FINALIZAR ou CANCELAR a requisição atual."
      @erro_padrao = true  
    end
  end

  # GET /requisicao_tis/1/edit
  def edit
    unless @requisicao_ti.pode_ser_editada
      flash[:error] = "Opss! Você não pode editar essa requisição."
      @erro_padrao = true  
    end
  end

  # POST /requisicao_tis or /requisicao_tis.json
  def create
    @requisicao_ti = RequisicaoTi.new(requisicao_ti_params)
    @requisicao_ti.user = current_user
    @requisicao_ti.unidade = current_user.unidade
    @requisicao_ti.status = 1
    
    respond_to do |format|
      if @requisicao_ti.save
        flash[:success] = "Requisição criada."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requisicao_tis/1 or /requisicao_tis/1.json
  def update
    respond_to do |format|
      if @requisicao_ti.update(requisicao_ti_params)
        flash[:success] = "Requisição atualizada."
        format.js {render :update, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /requisicao_tis/1 or /requisicao_tis/1.json
  def destroy
    if @requisicao_ti.status == "Solicitada"
      @requisicao_ti.status = "Cancelada"
      if @requisicao_ti.save
        flash.now[:success] = "Requisição Cancelada"
      else
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to requisicao_tis_url }
      format.json { head :no_content }
    end
  end

  def finalizar
    unless @requisicao_ti.pode_ser_finalizada(current_user)
      flash[:error] = "Opss! Você não pode finalizar essa requisição."
      @erro_padrao = true  
    end
  end

  def salvar
    respond_to do |format|
      if @requisicao_ti.update(requisicao_ti_params)
        flash[:success] = "Requisição finalizada."
        format.js {render :salvar, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :finalizar, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_ti
      @requisicao_ti = RequisicaoTi.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def requisicao_ti_params
      params.require(:requisicao_ti).permit(:status, :user_id, :unidade_id, :problema_ti_id, :observacoes, :solucao, 
                                            :comentario, :avaliacao, :data_hora_finalizada,
                                            :nome, :email, :cpf, :rg, :data_nascimento, :celular, :funcao_id, :cargo_id,
                                            :estado, :municipio, :perfil, :periodo_inicio, :periodo_fim, :unidade_id)
    end

    def verify_permission
      unless current_user.has_role? :req_serv_ti
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_problemas
      @aviso_requisicao_normal = nil
      if current_user.has_role? :req_serv_ti_sis
        if current_user.pode_solicitar_requisicao_ti_normal
          if current_user.unidade.tipo_unidade.nome == 'ESCOLA'
            @problemas = ProblemaTi.where("tipo_problema_ti_id = ? or tipo_problema_ti_id = ?", 3, 6).order(nome: :asc).all.map{ |p| [p.nome, p.id, {:nome => p.nome.downcase}] }    
          else  
            @problemas = ProblemaTi.where("tipo_problema_ti_id <> ?", 6).order(nome: :asc).all.map{ |p| [p.nome, p.id, {:nome => p.nome.downcase}] }
          end
        else
          @aviso_requisicao_normal = "Você pode solicitar mais de 1 requisições para sistemas web ao mesmo tempo! <br/> Você só pode solicitar uma requisição normal por vez!"
          @problemas = ProblemaTi.where("tipo_problema_ti_id = ? or tipo_problema_ti_id = ?", 3, 5).order(nome: :asc).all.map{ |p| [p.nome, p.id, {:nome => p.nome.downcase}] }  
        end
      elsif current_user.has_role? :req_serv_ti
        @problemas = ProblemaTi.where("tipo_problema_ti_id <> ? and tipo_problema_ti_id <> ?", 3, 6).order(nome: :asc).all.map{ |p| [p.nome, p.id, {:nome => p.nome.downcase}] }
      end
    end

    def load_unidades
      if current_user.has_role? :admin or current_user.has_role? :master
        @unidades = Unidade.order(nome: :asc).all.map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
      else
        @unidades = Unidade.order(nome: :asc).where(id: current_user.unidade_id).map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
      end
    end

    def load_funcoes
      if current_user.has_role? :master
        @funcoes = Funcao.order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      elsif current_user.has_role? :admin
        @funcoes = Funcao.where("nome <> ?", 'Master').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      else
        @funcoes = Funcao.where("nome <> ? and nome <> ?", 'master', 'admin').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      end
    end
     
    def load_cargos
      @cargos = Cargo.order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    end

    def load_perfis
      @perfis = ['RESPONSÁVEL POR UNIDADE', 'AUXILIAR DO RESPONSÁVEL', 'CONSULTA/RASCUNHO', 'ANALISTA']    
    end

    def load_municipios
      @municipios = ['Amapá', 'Calçoene', 'Cutias', 'Ferreira Gomes', 'Itaubal', 'Laranjal do Jarí', 'Macapá', 'Mazagão', 'Oiapoque', 'Pedra Branca do Amapari', 'Porto Grande', 'Pracuúba', 'Santana', 'Serra do Navio', 'Tartarugalzinho', 'Vitória do Jari']
    end

    def load_estados
      @estados = ['Amapá']
    end
    
end
