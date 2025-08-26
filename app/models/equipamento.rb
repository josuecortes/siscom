class Equipamento < ApplicationRecord
  belongs_to :unidade
  belongs_to :user
  has_many :item_movimentacoes, dependent: :destroy
  has_many :movimentacoes, through: :item_movimentacoes, source: :movimentacao_equipamento

  # Constantes
  TIPOS_EQUIPAMENTO = [
    'Gabinete', 'Monitor', 'Teclado', 'Mouse', 'Impressora', 'Scanner', 
    'Projetor', 'Tela de Projeção', 'Notebook', 'Tablet', 'Roteador', 
    'Switch', 'Servidor', 'Estabilizador', 'No-break', 'Cabo de Rede',
    'Cabo HDMI', 'Cabo VGA', 'Adaptador', 'Outro'
  ].freeze

  # Enums
  enum status: { ativo: 0, inativo: 1, em_manutencao: 2, descartado: 3 }

  # Validações
  validates_presence_of :tipo, :unidade_id, :user_id
  validates :tipo, inclusion: { in: %w[kit individual] }
  validates :status, inclusion: { in: %w[ativo inativo em_manutencao descartado] }
  validates :tipo_equipamento, inclusion: { in: TIPOS_EQUIPAMENTO }, if: :individual?
  
  # Validações para equipamentos individuais
  validates :marca, presence: true, if: :individual?
  validates :modelo, presence: true, if: :individual?
  validates :tipo_equipamento, presence: true, if: :individual?
  validates :garantia, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true
  
  # Validação de pelo menos um identificador
  validate :validar_identificadores_unicos, if: :individual?
  
  # Validações de unicidade
  validates :numero_serial, uniqueness: { scope: :tipo, case_sensitive: false }, allow_blank: true
  validates :numero_patrimonio, uniqueness: { scope: :tipo, case_sensitive: false }, allow_blank: true

  # Callbacks
  before_save :upcase_fields
  before_save :registrar_mudancas_historico
  after_create :criar_movimentacao_inicial

  # Scopes
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :por_status, ->(status) { where(status: status) }
  scope :por_unidade, ->(unidade_id) { where(unidade_id: unidade_id) }
  scope :por_tipo_equipamento, ->(tipo_equipamento) { where(tipo_equipamento: tipo_equipamento) }
  scope :por_identificacao_kit, ->(identificacao_kit) { where(identificacao_kit: identificacao_kit) }
  scope :ativos, -> { where(status: :ativo) }
  scope :individuais, -> { where(tipo: 'individual') }
  scope :kits, -> { where(tipo: 'kit') }

  # Métodos
  def upcase_fields
    self.marca.upcase! if self.marca
    self.modelo.upcase! if self.modelo
    self.numero_serial.upcase! if self.numero_serial
    self.numero_patrimonio.upcase! if self.numero_patrimonio
    self.outra_identificacao.upcase! if self.outra_identificacao
    self.identificacao_kit.upcase! if self.identificacao_kit
    self.host.upcase! if self.host
    self.ip.upcase! if self.ip
    self.contrato.upcase! if self.contrato
    self.processo.upcase! if self.processo
  end

  def gerar_codigo_kit
    loop do
      timestamp = Time.current
      codigo = timestamp.strftime('%Y%m%d%H%M%S')
      
      # Verificar se o código já existe
      unless Equipamento.exists?(codigo_kit: codigo)
        self.codigo_kit = codigo
        break
      end
      
      # Se existir, aguardar 1 segundo e tentar novamente
      sleep(1)
    end
  end

  def pelo_menos_um_identificador
    if numero_serial.blank? && numero_patrimonio.blank? && outra_identificacao.blank?
      errors.add(:base, "Pelo menos um dos campos deve ser preenchido: Número Serial, Patrimônio ou Outra Identificação")
    end
  end

  def validar_identificadores_unicos
    # Contar quantos identificadores estão preenchidos
    identificadores_preenchidos = 0
    identificadores_preenchidos += 1 if numero_serial.present?
    identificadores_preenchidos += 1 if numero_patrimonio.present?
    identificadores_preenchidos += 1 if outra_identificacao.present?
    
    if identificadores_preenchidos == 0
      errors.add(:base, "Pelo menos um dos campos deve ser preenchido: Número Serial, Patrimônio ou Outra Identificação")
    end
  end

  def registrar_mudancas_historico
    # Inicializar histórico se não existir
    self.historico_movimentacoes ||= []
    
    if new_record?
      # Registro de criação
      registrar_criacao
    else
      # Registro de mudanças
      registrar_mudancas
    end
  end

  def registrar_criacao
    movimentacao = {
      data: Time.current.iso8601,
      acao: 'cadastro',
      usuario: user&.nome || 'Sistema',
      usuario_id: user&.id,
      detalhes: "Equipamento cadastrado no sistema - Unidade: #{unidade&.sigla_nome || 'N/A'}",
      campos_alterados: {
        tipo: tipo,
        tipo_equipamento: tipo_equipamento,
        descricao: descricao,
        marca: marca,
        modelo: modelo,
        numero_serial: numero_serial,
        numero_patrimonio: numero_patrimonio,
        outra_identificacao: outra_identificacao,
        status: status,
        unidade_id: unidade_id,
        contrato: contrato,
        processo: processo,
        host: host,
        ip: ip,
        identificacao_kit: identificacao_kit,
        codigo_kit: codigo_kit,
        garantia: garantia
      },
      campos_especificos: {
        unidade: unidade&.sigla_nome || 'N/A'
      }
    }
    
    self.historico_movimentacoes << movimentacao
  end

  def registrar_mudancas
    # Verificar se houve mudança de unidade (movimentação)
    if changed.include?('unidade_id')
      unidade_anterior = Unidade.find_by(id: changes['unidade_id'][0])&.sigla_nome || 'N/A'
      unidade_nova = Unidade.find_by(id: changes['unidade_id'][1])&.sigla_nome || 'N/A'
      
      movimentacao = {
        data: Time.current.iso8601,
        acao: 'movimentacao',
        usuario: user&.nome || 'Sistema',
        usuario_id: user&.id,
        detalhes: "Movimentado de #{unidade_anterior} para #{unidade_nova}",
        campos_especificos: {
          unidade_origem: unidade_anterior,
          unidade_destino: unidade_nova
        }
      }
      
      self.historico_movimentacoes << movimentacao
    end
  end

  def adicionar_movimentacao(acao, detalhes, campos_especificos = nil)
    movimentacao = {
      data: Time.current.iso8601,
      acao: acao,
      usuario: user&.nome || 'Sistema',
      usuario_id: user&.id,
      detalhes: detalhes
    }
    
    movimentacao[:campos_especificos] = campos_especificos if campos_especificos
    
    self.historico_movimentacoes ||= []
    self.historico_movimentacoes << movimentacao
  end

  def transferir_para_unidade(nova_unidade_id, usuario)
    unidade_anterior = unidade.nome
    self.unidade_id = nova_unidade_id
    self.user_id = usuario.id
    
    if save
      adicionar_movimentacao('transferencia', "Transferido da unidade #{unidade_anterior} para #{unidade.nome}")
      true
    else
      false
    end
  end

  def alterar_status(novo_status, usuario)
    status_anterior = status
    self.status = novo_status
    self.user_id = usuario.id
    
    if save
      adicionar_movimentacao('alteracao_status', "Status alterado de #{status_anterior} para #{novo_status}")
      true
    else
      false
    end
  end

  def kit?
    tipo == 'kit'
  end

  def individual?
    tipo == 'individual'
  end

  def nome_completo
    if identificacao_kit.present?
      "#{tipo_equipamento} #{identificacao_principal} (Kit: #{identificacao_kit}) - #{unidade.sigla_nome}"
    else
      "#{tipo_equipamento} #{identificacao_principal} - #{unidade.sigla_nome}"
    end
  end

  def identificacao_principal
    if kit?
      identificacao_kit.presence || 'Sem identificação'
    else
      numero_patrimonio.presence || numero_serial.presence || outra_identificacao.presence || 'Sem identificação'
    end
  end

  def equipamentos_do_kit
    return [] unless codigo_kit.present?
    Equipamento.where(codigo_kit: codigo_kit, tipo: 'individual')
  end

  def kit_principal
    return nil unless individual? && codigo_kit.present?
    # Como não há mais equipamentos do tipo 'kit', retornamos o primeiro equipamento do mesmo kit
    Equipamento.where(codigo_kit: codigo_kit, tipo: 'individual').first
  end

  def pertence_a_kit?
    individual? && codigo_kit.present?
  end

  def nome_do_kit
    return nil unless pertence_a_kit?
    identificacao_kit
  end

  def codigo_do_kit
    return nil unless pertence_a_kit?
    codigo_kit
  end

  # Métodos para consultar o histórico
  def historico_por_acao(acao)
    return [] unless historico_movimentacoes.present?
    historico_movimentacoes.select { |h| h['acao'] == acao }
  end

  def historico_movimentacoes_entre_unidades
    return [] unless historico_movimentacoes.present?
    # Filtrar apenas movimentações relacionadas a criação e transferência entre unidades
    historico_movimentacoes.select { |h| ['cadastro', 'movimentacao'].include?(h['acao']) }
  end

  def ultima_movimentacao
    return nil unless historico_movimentacoes.present?
    historico_movimentacoes.last
  end

  def movimentacoes_por_usuario(usuario_id)
    return [] unless historico_movimentacoes.present?
    historico_movimentacoes.select { |h| h['usuario_id'] == usuario_id }
  end

  def movimentacoes_por_periodo(data_inicio, data_fim)
    return [] unless historico_movimentacoes.present?
    historico_movimentacoes.select do |h|
      data_mov = Time.parse(h['data'])
      data_mov >= data_inicio && data_mov <= data_fim
    end
  end

  def mudancas_por_campo(campo)
    return [] unless historico_movimentacoes.present?
    historico_movimentacoes.select do |h|
      h['mudancas']&.any? { |m| m['campo'] == campo }
    end
  end

  # Método para criar movimentação inicial quando equipamento é criado
  def criar_movimentacao_inicial
    return unless unidade_id.present? && user_id.present?

    # Para movimentação inicial, vamos pular todas as validações
    movimentacao = MovimentacaoEquipamento.new(
      unidade_origem: unidade,
      unidade_destino: unidade,
      responsavel: user,
      user: user,
      status: 'concluida',
      descricao: 'Movimentação inicial - Equipamento cadastrado',
      data_movimentacao: created_at
    )
    
    # Pular todas as validações para movimentação inicial
    movimentacao.save!(validate: false)

    # Criar item da movimentação
    movimentacao.item_movimentacoes.create!(
      equipamento: self,
      recebido: true,
      data_recebimento: created_at
    )
  rescue => e
    Rails.logger.error "Erro ao criar movimentação inicial: #{e.message}"
    # Não falhar a criação do equipamento se a movimentação inicial falhar
  end

  # Método para verificar se pode ter unidade alterada
  def pode_alterar_unidade?
    # Só pode alterar unidade através de movimentações
    false
  end

  # Override do setter de unidade_id para prevenir alterações diretas
  def unidade_id=(value)
    if persisted? && unidade_id_changed? && unidade_id_was.present?
      raise "Alteração de unidade deve ser feita através de movimentação"
    end
    super
  end

  def equipamentos_do_mesmo_kit
    return [] unless individual? && codigo_kit.present?
    Equipamento.where(codigo_kit: codigo_kit, tipo: 'individual').where.not(id: id)
  end

  def self.buscar(termo)
    where("marca ILIKE ? OR modelo ILIKE ? OR numero_serial ILIKE ? OR numero_patrimonio ILIKE ? OR identificacao_kit ILIKE ? OR contrato ILIKE ? OR processo ILIKE ?", 
          "%#{termo}%", "%#{termo}%", "%#{termo}%", "%#{termo}%", "%#{termo}%", "%#{termo}%", "%#{termo}%")
  end

  def self.criar_equipamentos_do_kit(kit_params, user)
    ActiveRecord::Base.transaction do
      # Validar parâmetros obrigatórios
      if kit_params[:identificacao_kit].blank?
        raise "Identificação do kit é obrigatória."
      end
      
      if kit_params[:unidade_id].blank?
        raise "Unidade é obrigatória."
      end
      
      # Gerar código único do kit
      codigo_kit = nil
      loop do
        timestamp = Time.current
        codigo_kit = timestamp.strftime('%Y%m%d%H%M%S')
        
        # Verificar se o código já existe
        unless Equipamento.exists?(codigo_kit: codigo_kit)
          break
        end
        
        # Se existir, aguardar 1 segundo e tentar novamente
        sleep(1)
      end
      
      # Criar os equipamentos individuais do kit (sem criar equipamento do tipo 'kit')
      equipamentos_criados = []
      
      if kit_params[:itens_kit].present?
        # Filtrar apenas itens válidos (com tipo_equipamento preenchido)
        itens_validos = kit_params[:itens_kit].select { |item| item[:tipo_equipamento].present? }
        
        if itens_validos.empty?
          raise "Pelo menos um item do kit deve ser preenchido com tipo de equipamento."
        end
        
        itens_validos.each_with_index do |item, index|
          # Validar campos obrigatórios do item
          if item[:tipo_equipamento].blank?
            raise "Tipo de equipamento é obrigatório para todos os itens do kit."
          end
          
          # Preparar atributos do equipamento individual
          equipamento_attrs = {
            tipo: 'individual',
            tipo_equipamento: item[:tipo_equipamento],
            descricao: kit_params[:descricao], # Mesma descrição do kit
            marca: item[:marca],
            modelo: item[:modelo],
            numero_serial: item[:numero_serial],
            numero_patrimonio: item[:numero_patrimonio],
            outra_identificacao: item[:outra_identificacao],
            garantia: item[:garantia],
            identificacao_kit: kit_params[:identificacao_kit], # Link com o kit
            codigo_kit: codigo_kit, # Mesmo código do kit
            contrato: kit_params[:contrato], # Mesmo contrato do kit
            processo: kit_params[:processo], # Mesmo processo do kit
            unidade_id: kit_params[:unidade_id], # Mesma unidade do kit
            user: user,
            status: item[:status] || 'ativo'
          }

          # Adicionar campos de rede se necessário
          if ['Impressora', 'Roteador', 'Switch'].include?(item[:tipo_equipamento])
            equipamento_attrs[:host] = item[:host] if item[:host].present?
            equipamento_attrs[:ip] = item[:ip] if item[:ip].present?
          elsif item[:tipo_equipamento] == 'Gabinete'
            equipamento_attrs[:host] = item[:host] if item[:host].present?
          end

          equipamento = new(equipamento_attrs)
          
          # Validar o equipamento antes de salvar
          unless equipamento.valid?
            # Capturar erros específicos
            equipamento.errors.full_messages.each do |message|
              if message.include?('já está em uso') || message.include?('already been taken')
                if message.include?('numero_serial') || message.include?('serial')
                  raise "Item #{index + 1}: Número serial '#{item[:numero_serial]}' já está em uso"
                elsif message.include?('numero_patrimonio') || message.include?('patrimonio')
                  raise "Item #{index + 1}: Número de patrimônio '#{item[:numero_patrimonio]}' já está em uso"
                else
                  raise "Item #{index + 1}: #{message}"
                end
              else
                raise "Item #{index + 1}: #{message}"
              end
            end
          end
          
          equipamento.save!
          equipamentos_criados << equipamento
        end
      else
        raise "Kit deve ter pelo menos um item."
      end

      # Retornar o primeiro equipamento criado como referência
      equipamentos_criados.first
    end
  end
end
