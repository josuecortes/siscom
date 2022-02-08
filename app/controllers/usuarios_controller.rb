class UsuariosController < ApplicationController
  before_action :set_usuario, only: %i[ show edit update destroy ]
  before_action :set_post_url, only: %i[ new create ]
  before_action :set_put_url, only: %i[ edit update ]
  

  # GET /usuarios or /usuarios.json
  def index
    @usuarios = User.autorizado(current_user).all
  end

  def autocomplete
    @usuarios = User.search(params[:term]).order(:nome)
    render json: @usuarios.map { |usuario| { id: usuario.id, value: usuario.nome } }
  end  
  
  # GET /usuarios/1 or /usuarios/1.json
  def show
  end

  # GET /usuarios/new
  def new
    @usuario = User.new
  end

  # GET /usuarios/1/edit
  def edit
   
  end

  # POST /usuarios or /usuarios.json
  def create
    @usuario = User.new(user_params)
    # @usuario.novo_usuario
    respond_to do |format|
      if @usuario.save
        flash[:success] = "Usuário criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new }
      end
    end
  end

  # PATCH/PUT /usuarios/1 or /usuarios/1.json
  def update
    respond_to do |format|
      if @usuario.update(user_params)
        flash[:success] = "Usuário atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit }
      end
    end
  end

  # DELETE /usuarios/1 or /usuarios/1.json
  def destroy
    if @usuario.destroy
      flash[:success] = "Usuário excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to usuarios_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_usuario
      @usuario = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:nome, :email, :departamento_id, :funcao_id, role_ids: [])
    end

    def set_post_url
      @url = usuarios_path
      @method = 'post'
    end

    def set_put_url
      @url = usuario_path(@usuario)
      @method = 'put'
    end  
end
