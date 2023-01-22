class RequisicaoTisController < ApplicationController
  before_action :verify_permission
  before_action :set_requisicao_ti, only: %i[ show edit update destroy finalizar salvar ]  

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
  end

  # GET /requisicao_tis/1 or /requisicao_tis/1.json
  def show
  end

  # GET /requisicao_tis/new
  def new
    if current_user.pode_solicitar_requisicao_ti
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
    if @requisicao_ti.status == 1
      @requisicao_ti.status = 4
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
      params.require(:requisicao_ti).permit(:status, :user_id, :unidade_id, :problema_ti_id, :observacoes, :solucao, :comentario, :avaliacao)
    end

    def verify_permission
      unless current_user.has_role? :req_serv_ti
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end
end
