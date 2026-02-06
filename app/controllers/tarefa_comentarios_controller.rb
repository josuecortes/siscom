class TarefaComentariosController < ApplicationController
  before_action :set_tarefa

  def index
    carregar_comentarios
    @tarefa_comentario = @tarefa.comentarios.new

    respond_to do |format|
      format.js
    end
  end

  def new
    carregar_comentarios
    @tarefa_comentario = @tarefa.comentarios.new

    respond_to do |format|
      format.js
    end
  end

  def create
    @tarefa_comentario = @tarefa.comentarios.new(comentario_params)
    @tarefa_comentario.user = current_user

    if @tarefa_comentario.save
      carregar_comentarios
    end

    respond_to do |format|
      format.js
    end
  end

  private
    def set_tarefa
      @tarefa = Tarefa.find(params[:tarefa_id])
    end

    def carregar_comentarios
      @comentarios = @tarefa.comentarios.includes(:user).order(created_at: :desc)
    end

    def comentario_params
      params.require(:tarefa_comentario).permit(:texto)
    end
end
