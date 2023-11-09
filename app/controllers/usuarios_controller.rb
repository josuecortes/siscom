class UsuariosController < ApplicationController
  before_action :set_usuario, only: %i[ show edit update destroy resetar_senha tornar_requisitante_transporte tornar_tecnico_transporte ]
  before_action :set_post_url, only: %i[ new create ]
  before_action :set_put_url, only: %i[ edit update ]
  before_action :load_unidade, :load_funcoes, only: %i[ new edit update create ]
  

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

  def resetar_senha
    if @usuario.resetar_senha
      flash[:success] = "A senha foi resetada com sucesso - (Seed@123)."
    else
      flash[:error] = "Erro ao resetar a senha."
    end

    respond_to do |format|
      format.html { redirect_to usuarios_url }
    end
  end

  def tornar_requisitante_transporte
    role = Role.where('name = ?', 'req_serv_tp').first
    if params['remove']
      if @usuario.has_role? :req_serv_tp
        @usuario.roles.delete(role)  
      end
    else
      unless @usuario.has_role? :req_serv_tp
        @usuario.roles << role
      end
    end  
    if @usuario.save
      flash[:success] = "Permissão de requisitante de transporte #{params['remove'] ? 'removida' : 'adicionada'}."
    else
      flash[:error] = "Erro ao #{params['remove'] ? 'remover' : 'adicionar'} permissão."
    end

    respond_to do |format|
      format.html { redirect_to usuarios_url }
    end
  end

  def tornar_tecnico_transporte
    role = Role.where('name = ?', 'tec_serv_tp').first
    if params['remove']
      if @usuario.has_role? :tec_serv_tp
        @usuario.roles.delete(role)  
      end
    else
      unless @usuario.has_role? :tec_serv_tp
        @usuario.roles << role
      end
    end 
    if @usuario.save
      flash[:success] = "Permissão de técnico de transporte #{params['remove'] ? 'removida' : 'adicionada'}."
    else
      flash[:error] = "Erro ao #{params['remove'] ? 'remover' : 'adicionar'} permissão."
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
      params.require(:user).permit(:nome, :email, :unidade_id, :funcao_id, role_ids: [])
    end

    def set_post_url
      @url = usuarios_path
      @method = 'post'
    end

    def set_put_url
      @url = usuario_path(@usuario)
      @method = 'put'
    end  

    def load_funcoes
      if current_user.has_role? :master
        @funcoes = Funcao.order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      elsif current_user.has_role? :admin
        @funcoes = Funcao.where("nome <> ?", 'Master').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      elsif current_user.has_role? :tec_serv_ti  or current_user.has_role? :tec_serv_tp
        @funcoes = Funcao.where("nome <> ? and nome <> ?", 'master', 'admin').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      else
        @funcoes = Funcao.order(nome: :asc).where(id: current_user.funcao_id).map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
      end
    end

    def load_unidade
      if current_user.has_role? :admin or current_user.has_role? :master or current_user.has_role? :tec_serv_tp
        @unidades = Unidade.order(nome: :asc).all.map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
      else
        @unidades = Unidade.order(nome: :asc).where(id: current_user.unidade_id).map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
      end
    end
end
