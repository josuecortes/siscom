class TransporteEscolar::MunicipiosController < ApplicationController
  before_action :set_transporte_escolar_municipio, only: %i[ show edit update destroy ]
  before_action :verify_permission 

  # GET /transporte_escolar/municipios or /transporte_escolar/municipios.json
  def index
    @transporte_escolar_municipios = TransporteEscolar::Municipio.all
  end

  # GET /transporte_escolar/municipios/1 or /transporte_escolar/municipios/1.json
  def show
  end

  # GET /transporte_escolar/municipios/new
  def new
    @transporte_escolar_municipio = TransporteEscolar::Municipio.new
  end

  # GET /transporte_escolar/municipios/1/edit
  def edit
  end

  # POST /transporte_escolar/municipios or /transporte_escolar/municipios.json
  def create
    @transporte_escolar_municipio = TransporteEscolar::Municipio.new(transporte_escolar_municipio_params)

    respond_to do |format|
      if @transporte_escolar_municipio.save
        format.html { redirect_to transporte_escolar_municipio_url(@transporte_escolar_municipio), notice: "Municipio was successfully created." }
        format.json { render :show, status: :created, location: @transporte_escolar_municipio }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @transporte_escolar_municipio.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transporte_escolar/municipios/1 or /transporte_escolar/municipios/1.json
  def update
    respond_to do |format|
      if @transporte_escolar_municipio.update(transporte_escolar_municipio_params)
        format.html { redirect_to transporte_escolar_municipio_url(@transporte_escolar_municipio), notice: "Municipio was successfully updated." }
        format.json { render :show, status: :ok, location: @transporte_escolar_municipio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @transporte_escolar_municipio.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transporte_escolar/municipios/1 or /transporte_escolar/municipios/1.json
  def destroy
    if @transporte_escolar_municipio.destroy
      flash[:success] = "Municipio apagado"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to transporte_escolar_municipios_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transporte_escolar_municipio
      @transporte_escolar_municipio = TransporteEscolar::Municipio.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def transporte_escolar_municipio_params
      params.require(:transporte_escolar_municipio).permit(:nome, :tipo)
    end

    def verify_permission
      if !current_user.has_role? :ges_tp_es and !current_user.has_role? :tec_tp_es and !current_user.has_role? :master 
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end
end
