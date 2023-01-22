class PerfilController < ApplicationController
  before_action :load_unidade, :load_funcoes

  def index
    @usuario = current_user
  end

  def update
    @usuario = current_user
    if @usuario.update(user_params)
      flash[:success] = 'Usuário atualizado'
      redirect_to perfil_index_path(@usuario) 
    else
      flash.now[:error] = "Opss! Algo deu errado."
      render :index 
    end
  end

  def alterar_senha
    @usuario = current_user
  end

  def salvar_senha
    @usuario = current_user
    if @usuario.alterar_senha(user_params)
      flash[:success] = 'Senha alterada, efetue o login para continuar.'
      redirect_to new_user_session_url
    else
      flash.now[:error] = "Opss! Algo deu errado."
      render :alterar_senha 
    end
  end

  private

  def user_params
    params.require(:user).permit(:nome, :email, :avatar, :unidade_id, :funcao_id, :current_password, :password, :password_confirmation)
  end

  def load_funcoes
    if current_user.has_role? :master
      @funcoes = Funcao.order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    elsif current_user.has_role? :admin
      @funcoes = Funcao.where("nome <> ?", 'Master').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    elsif current_user.has_role? :tec_serv_ti
      @funcoes = Funcao.where("nome <> ? and nome <> ?", 'master', 'admin').order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    else
      @funcoes = Funcao.order(nome: :asc).where(id: current_user.funcao_id).map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    end
  end

  def load_unidade
    if current_user.has_role? :admin or current_user.has_role? :master
      @unidades = Unidade.order(nome: :asc).all.map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
    else
      @unidades = Unidade.order(nome: :asc).where(id: current_user.unidade_id).map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
    end
  end
end
