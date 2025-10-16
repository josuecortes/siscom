class UsuariosController < ApplicationController
  before_action :set_usuario, only: %i[ show edit update destroy resetar_senha tornar_requisitante_transporte tornar_tecnico_transporte ]
  before_action :set_post_url, only: %i[ new create ]
  before_action :set_put_url, only: %i[ edit update ]
  before_action :load_unidade, :load_funcoes, only: %i[ new edit update create ]
  

  # GET /usuarios or /usuarios.json
  def index
    respond_to do |format|
      format.html do
        # A listagem agora será carregada via DataTables (server-side)
      end
      format.json do
        base_scope = User.autorizado(current_user).left_joins(:unidade).includes(:unidade).distinct

        records_total = base_scope.count

        # Busca global
        if params.dig(:search, :value).present?
          term = "%#{params[:search][:value]}%"
          base_scope = base_scope.where(
            "users.nome ILIKE :t OR users.email ILIKE :t OR unidades.nome ILIKE :t OR unidades.sigla ILIKE :t",
            t: term
          )
        end

        records_filtered = base_scope.count

        # Ordenação
        order_index = params.dig(:order, '0', :column).to_i rescue 0
        order_dir = params.dig(:order, '0', :dir) == 'desc' ? 'desc' : 'asc'
        order_column = case order_index
                       when 0 then 'users.nome'
                       when 1 then 'users.email'
                       when 2 then 'unidades.nome'
                       else 'users.nome'
                       end
        base_scope = base_scope.order(Arel.sql("#{order_column} #{order_dir}"))

        # Paginação
        start = params[:start].to_i
        length = params[:length].to_i
        length = 25 if length <= 0
        length = 100 if length > 100

        usuarios = base_scope.offset(start).limit(length)

        data = usuarios.map do |u|
          acoes = []
          acoes << view_context.link_to(view_context.edit_usuario_path(u), { class: "btn btn-sm btn-primary", title: "Editar", remote: true }) do
            '<i class="fas fa-edit"></i>'.html_safe
          end

          if current_user.has_any_role? :tec_serv_ti, :admin, :master
            acoes << view_context.link_to(view_context.resetar_senha_usuario_path(u), { data: { confirm: 'Tem certeza?' }, class: "btn btn-sm btn-warning", title: "Resetar Senha", remote: true }) do
              '<i class="fas fa-sync-alt"></i>'.html_safe
            end

            if u.status == true
              acoes << view_context.link_to(view_context.usuario_path(u), { method: :delete, data: { confirm: 'Tem certeza?' }, class: "btn btn-sm btn-danger", title: "Desativar", remote: true }) do
                '<i class="fas fa-close"></i>'.html_safe
              end
            else
              acoes << view_context.link_to(view_context.usuario_path(u), { method: :delete, data: { confirm: 'Tem certeza?' }, class: "btn btn-sm btn-success", title: "Reativar", remote: true }) do
                '<i class="fas fa-check"></i>'.html_safe
              end
            end
          end

          if current_user.has_role? :tec_serv_tp
            unless u.has_role? :req_serv_tp
              acoes << view_context.link_to(view_context.tornar_requisitante_transporte_usuario_path(u), { data: { confirm: 'Adicionar permissão?' }, class: "btn btn-sm btn-default", title: "Tornar requisitante de serviço de transporte", remote: true }) do
                '<i class="fas fa-car"></i> Requisitante'.html_safe
              end
            else
              acoes << view_context.link_to(view_context.tornar_requisitante_transporte_usuario_path(u, remove: true), { data: { confirm: 'Remover permissão?' }, class: "btn btn-sm btn-danger", title: "Remover permissão requisitante de serviço de transporte", remote: true }) do
                '<i class="fas fa-car"></i> Remover Requisitante'.html_safe
              end
            end

            unless u.has_role? :tec_serv_tp
              acoes << view_context.link_to(view_context.tornar_tecnico_transporte_usuario_path(u), { data: { confirm: 'Adicionar permissão?' }, class: "btn btn-sm btn-default", title: "Tornar técnico de serviço de transporte", remote: true }) do
                '<i class="fas fa-user"></i> Técnico'.html_safe
              end
            else
              acoes << view_context.link_to(view_context.tornar_tecnico_transporte_usuario_path(u, remove: true), { data: { confirm: 'Remover permissão?' }, class: "btn btn-sm btn-danger", title: "Remover permissão técnico de serviço de transporte", remote: true }) do
                '<i class="fas fa-user"></i> Remover Técnico'.html_safe
              end
            end
          end

          [
            u.nome,
            u.email,
            (u.unidade&.sigla || 'SEM UNIDADE.'),
            acoes.join(' ').html_safe
          ]
        end

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: records_total,
          recordsFiltered: records_filtered,
          data: data
        }
      end
    end
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
        format.js { render :update  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit }
      end
    end
  end

  # DELETE /usuarios/1 or /usuarios/1.json
  def destroy
    @usuario.status = !@usuario.status.presence

    if @usuario.save
      @erro = false
      @mensagem = "Usuário atualizado."
    else
      @erro = true
      @mensagem = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to usuarios_url }
      format.js {}
    end
  end

  def resetar_senha
    respond_to do |format|
      if @usuario.resetar_senha
        @erro = false
        @mensagem = "A senha foi resetada com sucesso - (Seed@123)."
        format.html { redirect_to usuarios_url }
        format.js { }
      else
        @erro = true
        @mensagem = "Erro ao resetar a senha."
        format.html { redirect_to usuarios_url }
        format.js {}
      end
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
      @erro = false
      @mensagem = "Permissão de requisitante de transporte #{params['remove'] ? 'removida' : 'adicionada'}."
    else
      @erro = true
      @mensagem = "Erro ao #{params['remove'] ? 'remover' : 'adicionar'} permissão."
    end

    respond_to do |format|
      format.html { redirect_to usuarios_url }
      format.js {}
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
      @erro = false
      @mensagem = "Permissão de técnico de transporte #{params['remove'] ? 'removida' : 'adicionada'}."
    else
      @erro = true
      @mensagem = "Erro ao #{params['remove'] ? 'remover' : 'adicionar'} permissão."
    end

    respond_to do |format|
      format.html { redirect_to usuarios_url }
      format.js {}
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
