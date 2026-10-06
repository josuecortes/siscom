module Equipamentos
  # Equipamento (porta de equipamento.rb do siscom antigo). Pertence a uma unidade (a dona); só muda de unidade
  # por movimentação recebida. Enquanto está num envio aberto (`situacao`), não pode ser editado nem entrar em outro.
  class Item < ApplicationRecord
    self.table_name = "equipamentos_itens"

    TIPOS = [ "Gabinete", "Monitor", "Teclado", "Mouse", "Impressora", "Scanner", "Projetor", "Tela de Projeção", "Notebook", "Tablet", "Roteador",
              "Switch", "Servidor", "Estabilizador", "No-break", "Cabo de Rede", "Cabo HDMI", "Cabo VGA", "Adaptador", "Outro" ].freeze
    STATUS = { "ativo" => "Ativo", "inativo" => "Inativo", "em_manutencao" => "Em manutenção", "descartado" => "Descartado" }.freeze
    SITUACOES = { "disponivel" => "Disponível", "em_movimentacao" => "Em movimentação", "emprestado" => "Emprestado" }.freeze
    # Campos que o formulário grava (e que entram no histórico quando mudam), com o nome que aparece na tela.
    CAMPOS = { tipo_equipamento: "Tipo de equipamento", marca: "Marca", modelo: "Modelo", numero_serial: "Número serial", numero_patrimonio: "Número do patrimônio",
               outra_identificacao: "Outra identificação", descricao: "Descrição", garantia: "Garantia (meses)", contrato: "Contrato ou referência",
               processo: "Processo", host: "Host", ip: "IP", mac: "MAC", ativo_de_rede: "Ativo de rede", localizacao_fisica: "Localização física", rack: "Rack" }.freeze
    EM_MAIUSCULAS = %i[marca modelo numero_serial numero_patrimonio outra_identificacao identificacao_kit host ip contrato processo mac ativo_de_rede].freeze

    belongs_to :cadastrado_por, class_name: "User", optional: true
    has_many :eventos, class_name: "Equipamentos::Evento", foreign_key: :item_id, inverse_of: :item, dependent: :destroy
    has_many :itens_de_movimentacao, class_name: "Equipamentos::ItemMovimentacao", foreign_key: :item_id, inverse_of: :item, dependent: :restrict_with_error

    enum :status, STATUS.keys.index_by(&:itself), validate: true
    enum :situacao, SITUACOES.keys.index_by(&:itself), validate: true

    normalizes(*EM_MAIUSCULAS, with: ->(texto) { texto.to_s.squish.upcase.presence })
    normalizes :descricao, :localizacao_fisica, :rack, :codigo_kit, with: ->(texto) { texto.to_s.squish.presence }

    validates :tipo_equipamento, inclusion: { in: TIPOS, message: "deve ser escolhido na lista" }
    validates :marca, :modelo, :rh_unidade_id, :unidade_nome, presence: true
    validates :garantia, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :numero_serial, :numero_patrimonio, uniqueness: { case_sensitive: false, message: "já está em outro equipamento" }, allow_nil: true
    validates :mac, presence: true, uniqueness: { case_sensitive: false }, if: :switch?
    validates :ativo_de_rede, presence: true, if: :switch?
    validate :ao_menos_um_identificador

    scope :em_ordem, -> { order(:codigo_kit, :tipo_equipamento, :marca, :modelo, :id) }
    scope :recentes, -> { order(created_at: :desc, id: :desc) }
    scope :buscar, ->(termo) {
      padrao = "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%"
      where(%w[marca modelo numero_serial numero_patrimonio outra_identificacao identificacao_kit codigo_kit contrato processo host ip mac ativo_de_rede localizacao_fisica rack
               tipo_equipamento descricao].map { |coluna| "UPPER(equipamentos_itens.#{coluna}) LIKE :t" }.join(" OR "), t: padrao)
    }
    # Da unidade: os que são dela e os que estão com ela emprestados.
    scope :das_unidades, ->(ids) { where(rh_unidade_id: ids).or(where(posse_rh_unidade_id: ids)) }

    def switch? = tipo_equipamento == "Switch"
    def no_kit? = codigo_kit.present?
    def nome_do_status = STATUS[status]
    def nome_da_situacao = SITUACOES[situacao]
    def identificacao = numero_patrimonio.presence || numero_serial.presence || outra_identificacao.presence || "Sem identificação"
    def nome = "#{tipo_equipamento} #{marca} #{modelo}"
    def nome_completo = "#{nome} · #{identificacao}"

    # Livre para editar, movimentar ou emprestar: ativo e fora de qualquer envio aberto.
    def livre? = ativo? && disponivel?

    def registrar_evento(tipo, ator, nota = nil, mudancas: {}, em: Time.current)
      eventos.create!(tipo: tipo, ator: ator, ator_nome: ator&.nome, nota: nota.to_s.squish.presence, mudancas: mudancas, ocorrido_em: em)
    end

    # Próximo código de kit (KIT-000001…): o maior que existe mais um. No siscom antigo era a hora do relógio, com
    # espera de 1 segundo. Chame dentro de uma transação: a trava segura dois cadastros de kit ao mesmo tempo.
    def self.proximo_codigo_de_kit
      connection.execute("SELECT pg_advisory_xact_lock(7306001)")
      ultimo = where("codigo_kit LIKE 'KIT-%'").maximum(Arel.sql("NULLIF(regexp_replace(codigo_kit, '\\D', '', 'g'), '')::bigint")).to_i
      format("KIT-%06d", ultimo + 1)
    end

    private

    def ao_menos_um_identificador
      return if numero_serial.present? || numero_patrimonio.present? || outra_identificacao.present?

      errors.add(:base, "Preencha pelo menos um identificador: número serial, patrimônio ou outra identificação.")
    end
  end
end
