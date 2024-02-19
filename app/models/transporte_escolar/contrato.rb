class TransporteEscolar::Contrato < ApplicationRecord
  # fields
  # t.string "codigo", presence, unique
  # t.string "rota"
  # t.text "descricao", presence
  # t.date "inicio", presence
  # t.date "fim", presence
  # t.bigint "valor_total", presence
  # t.string "valor_diaria", presence
  # t.bigint "transportador_id", null: false, presence
  # t.bigint "escola_id", null: false, presence
  # t.bigint "veiculo_id", null: false, presence

  belongs_to :transportador, class_name: 'TransporteEscolar::Transportador'
  belongs_to :escola, class_name: 'TransporteEscolar::Escola'
  belongs_to :veiculo, class_name: 'TransporteEscolar::Veiculo'

  has_many :servicos, class_name: 'TransporteEscolar::Servico'

  validates_presence_of :codigo, :descricao, :transportador_id, :escola_id, :inicio, :fim, :veiculo_id
  
  validate :validar_inicio_fim
  validate :validar_valores

  after_create :criar_servicos
  before_update :verificar_servicos_antes_de_atualizar
  before_destroy :verificar_servicos_antes_de_deletar
  before_save :upcase_fields

  private

  def validar_inicio_fim
    if fim.present? && inicio.present?
      if fim.is_a?(Date) && inicio.is_a?(Date)
        if fim < inicio
          errors.add(:inicio, 'deve ser menor que a data final')
          errors.add(:fim, 'deve ser maior que a data inicial')
        end
      else
        errors.add(:inicio, 'deve ser uma data válida') unless inicio.is_a?(Date)
        errors.add(:fim, 'deve ser uma data válida') unless fim.is_a?(Date)
      end
    end
  end

  def validar_valores
    if valor_total.present? && valor_diaria.present?
      if valor_total.is_a?(Float) && valor_diaria.is_a?(Float)
        if valor_total <= valor_diaria
          errors.add(:valor_total, 'deve ser maior que o valor da diária')
          errors.add(:valor_diaria, 'deve ser menor que o valor total')
        end
      else
        errors.add(:valor_total, 'deve ser um valor válido') unless valor_total.is_a?(Float)
        errors.add(:valor_diaria, 'deve ser um valor válido') unless valor_diaria.is_a?(Float)
      end
    end
  end

  def criar_servicos
    
    transaction do
      data_inicio = inicio.beginning_of_month
      data_fim = fim.end_of_month

      (data_inicio..data_fim).select { |d| d.day == 1 }.each do |data_mes|
        servico = TransporteEscolar::Servico.new(
          numero: '',
          diarias: 0,
          contrato_id: self.id,
          status: 'Em aberto',
          ano_mes: data_mes.strftime("%m/%Y")
        )
        
        unless servico.save!
          raise ActiveRecord::Rollback, "Erro ao criar o serviço para o mês #{data_mes}"
        end
      end
    end
  end

  def verificar_servicos_antes_de_atualizar
    # Verifica se o valor_total ou valor_diaria está sendo alterado e existem serviços não pagáveis
    if (valor_total_changed? || valor_diaria_changed?) && servicos.where.not(status: 'Em aberto').exists?
      errors.add(:base, 'Não é possível alterar o valor total ou a diária, pois existem serviços já iniciados ou concluídos.')
      throw :abort
    end

    if (inicio_changed? || fim_changed?) && servicos.where.not(status: 'Em aberto').exists?
      errors.add(:base, 'Não é possível alterar o início ou fim, pois existem serviços já iniciados ou concluídos.')
      throw :abort
    elsif inicio_changed? || fim_changed?
      errors.add(:base, 'Não é possível alterar o início ou fim, mas, você ainda pode apagar esse contrato e criar um novo pois não existem serviços iniciados nem concluídos.')
      throw :abort
    end

    # Verifica se as datas de início ou fim estão sendo alteradas e afetam serviços não pagáveis
    # if inicio_changed? || fim_changed?
    #   data_inicial = inicio_was
    #   data_final = fim_was
    #   servicos_afetados = servicos.where.not(status: 'Em aberto').where("to_char(ano_mes, 'MM/YYYY') BETWEEN ? AND ?", data_inicial.strftime('%m/%Y'), data_final.strftime('%m/%Y'))
    #   if servicos_afetados.exists?
    #     errors.add(:base, "Não é possível alterar as datas de início ou fim, pois existem serviços com status diferente de 'Em aberto' no intervalo alterado.")
    #     throw :abort
    #   end
    # end
  end

  def verificar_servicos_antes_de_deletar
    if servicos.where.not(status: 'Em aberto').exists?
      errors.add(:base, 'Não é possível deletar o contrato, pois existem serviços com status diferente de "Em aberto" ou Concluídos.')
      throw :abort
    else
      servicos.destroy_all
    end
  end

  def upcase_fields
    self.rota.upcase! if self.rota
    self.codigo.upcase! if self.codigo
  end

end
