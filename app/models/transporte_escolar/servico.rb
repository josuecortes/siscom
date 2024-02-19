class TransporteEscolar::Servico < ApplicationRecord
  
  belongs_to :contrato, class_name: "TransporteEscolar::Contrato"

  validates_presence_of :contrato_id, :status, :ano_mes
  validates_uniqueness_of :ano_mes, scope: :contrato_id, message: 'já existe um serviço para este mês no contrato selecionado'
  validates_uniqueness_of :numero, allow_blank: true, message: 'número já utilizado'
  validates :diarias, presence: true, numericality: { greater_than: 1 }, if: -> { status == "Pago" }

  enum status: { "Em aberto": 1,  "Pago": 2 }  

  def calcular_valor
    valor_diaria = self.contrato.valor_diaria
    return 0 if valor_diaria <= 0
    return 0 if diarias <= 0
    
    valor_diaria * diarias
  end  

  def pendencias
    [].tap do |array_pendencias|
      
      valor_total = contrato.valor_total
      valor_pago = calcular_valor
      
      if status == "Pago"
        if valor_total != valor_pago
          array_pendencias << "Valor integral do contrato: #{valor_total.real_contabil} é diferente do Valor pago: #{valor_pago.real_contabil}"
        end
      end
      
      array_pendencias << "Dias trabalhados inválido" if diarias < 0 
      
      array_pendencias << "Dias trabalhados foi preenchido, mas o status está diferente de 'Pago'" if diarias > 0 && status != "Pago"
      
      array_pendencias << "Nota de pagamento não informada" unless nota
      array_pendencias << "Boletim não informado" unless boletim
    end
  end
end
