class PerfilController < ApplicationController
  before_action :load_departamento, :load_funcoes

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

  private

  def user_params
    params.require(:user).permit(:nome, :email, :avatar, :departamento_id, :funcao_id)
  end

  def load_funcoes
    if current_user.has_role? :tec_serv_ti or current_user.has_role? :master
      @funcoes = Funcao.order(nome: :asc).all.map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    else
      @funcoes = Funcao.order(nome: :asc).where(id: current_user.funcao_id).map{ |f| [f.nome, f.id, {:nome => f.nome.downcase}] }
    end
  end

  def load_departamento
    if current_user.has_role? :tec_serv_ti or current_user.has_role? :master
      @departamentos = Departamento.order(nome: :asc).all.map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
    else
      @departamentos = Departamento.order(nome: :asc).where(id: current_user.departamento_id).map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
    end
  end
end
