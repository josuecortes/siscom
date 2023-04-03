class PatioController < ApplicationController
  def index
    @veiculos_garagem = Veiculo.com_status(1)
    @motoristas_garagem = Motorista.com_status(1)
    @veiculos_no_patio = Veiculo.com_status(2)
    @veiculos_em_servico = Veiculo.com_status(3)
  end

  def entrada
    
    if params[:veiculo_id] and params[:veiculo_id] != "Selecione o veículo..."
      @veiculo = Veiculo.com_status(1).find(params[:veiculo_id]) 
    end
    if params[:motorista_id] and params[:motorista_id] != "Selecione o motorista..."
      @motorista = Motorista.com_status(1).find(params[:motorista_id]) 
    end
    if @veiculo and @motorista
      @motorista.status = 'em_servico'
      @veiculo.status = 'patio'
      @veiculo.motorista = @motorista
      if @veiculo.save! and @motorista.save!
        flash[:success] = "Veículo adicionado ao Patio"
      else
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    redirect_to patio_index_path
  end

  def saida
    @veiculo = Veiculo.com_status(2).find(params[:veiculo_id])
    @motorista = Motorista.com_status(2).find(params[:motorista_id])
    if @veiculo and @motorista
      @motorista.status = 'garagem'
      @veiculo.status = 'garagem'
      @veiculo.motorista_id = nil
      if @veiculo.save! and @motorista.save!
        flash[:success] = "Veículo saiu do patio"
      else
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    redirect_to patio_index_path
  end

end
