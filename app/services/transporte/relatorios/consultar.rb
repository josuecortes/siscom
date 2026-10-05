module Transporte
  module Relatorios
    # Relatórios do Transporte (porta de reports/query_service.rb do seed): por veículo, por motorista
    # e por solicitação, num período. Devolve colunas, linhas e um resumo, prontos para a tela e o Excel.
    #
    #   Transporte::Relatorios::Consultar.call(tipo: "veiculos", filtros: { inicio: "01/10/2026", fim: "31/10/2026" })
    class Consultar
      TIPOS = { "solicitacoes" => "Solicitações", "veiculos" => "Veículos", "motoristas" => "Motoristas" }.freeze
      Relatorio = Data.define(:tipo, :titulo, :colunas, :linhas, :resumo, :inicio, :fim)

      def self.call(...) = new(...).call

      def initialize(tipo:, filtros: {})
        @tipo = TIPOS.key?(tipo.to_s) ? tipo.to_s : "solicitacoes"
        filtros = filtros.to_h.symbolize_keys
        @inicio = DataBr.interpretar(filtros[:inicio]) || Date.current.beginning_of_month
        @fim = DataBr.interpretar(filtros[:fim]) || Date.current
        @inicio, @fim = @fim, @inicio if @inicio > @fim
        @status = filtros[:status].presence_in(Transporte::Solicitacao::STATUS.keys)
        @motorista_id = filtros[:motorista_id].presence
        @veiculo_id = filtros[:veiculo_id].presence
        @busca = filtros[:q].to_s.squish
      end

      def call
        colunas, linhas, resumo = send(@tipo)
        Relatorio.new(tipo: @tipo, titulo: TIPOS[@tipo], colunas: colunas, linhas: linhas, resumo: resumo, inicio: @inicio, fim: @fim)
      end

      private

      def periodo = @inicio.beginning_of_day..@fim.end_of_day

      def servicos
        servicos = Transporte::Servico.where(iniciado_em: periodo).includes(:veiculo, :solicitacao)
        servicos = servicos.where(motorista_id: @motorista_id) if @motorista_id
        servicos = servicos.where(veiculo_id: @veiculo_id) if @veiculo_id
        servicos.to_a
      end

      # Trechos da mesma saída em grupo são uma viagem só: os quilômetros não são somados duas vezes.
      def viagens(servicos) = servicos.group_by { |servico| servico.grupo.presence || "s#{servico.id}" }.values

      def km_das(viagens)
        viagens.sum do |trechos|
          finais = trechos.filter_map(&:odometro_final)
          finais.any? ? finais.max - trechos.map(&:odometro_inicial).min : 0
        end
      end

      def veiculos
        por_veiculo = servicos.group_by(&:veiculo)
        linhas = por_veiculo.map do |veiculo, trechos|
          km = km_das(viagens(trechos))
          [ veiculo.placa, "#{veiculo.marca} #{veiculo.modelo}", viagens(trechos).size, trechos.map(&:solicitacao_id).uniq.size, km,
            (km / veiculo.consumo_km_por_litro).round(1).to_f, veiculo.odometro_atual ]
        end.sort_by(&:first)
        [ [ "Placa", "Veículo", "Viagens", "Solicitações", "Km rodados", "Litros estimados", "Odômetro atual" ], linhas,
          { "Veículos com serviço" => linhas.size, "Viagens" => linhas.sum { |l| l[2] }, "Km rodados" => linhas.sum { |l| l[4] },
            "Litros estimados" => linhas.sum { |l| l[5] }.round(1) } ]
      end

      def motoristas
        linhas = servicos.group_by { |servico| [ servico.motorista_id, servico.motorista_nome ] }.map do |(_, nome), trechos|
          [ nome, viagens(trechos).size, trechos.map(&:solicitacao_id).uniq.size, km_das(viagens(trechos)), trechos.map(&:placa).uniq.sort.join(", ") ]
        end.sort_by(&:first)
        [ [ "Motorista", "Viagens", "Solicitações", "Km rodados", "Veículos" ], linhas,
          { "Motoristas com serviço" => linhas.size, "Viagens" => linhas.sum { |l| l[1] }, "Km rodados" => linhas.sum { |l| l[3] } } ]
      end

      def solicitacoes
        solicitacoes = Transporte::Solicitacao.where(saida_em: periodo).includes(:destinos, :servicos).order(:saida_em, :id)
        solicitacoes = solicitacoes.where(status: @status) if @status
        solicitacoes = solicitacoes.buscar(@busca) if @busca.present?
        com_servico = Transporte::Servico.where(motorista_id: @motorista_id) if @motorista_id
        com_servico = (com_servico || Transporte::Servico).where(veiculo_id: @veiculo_id) if @veiculo_id
        solicitacoes = solicitacoes.where(id: com_servico.select(:solicitacao_id)) if com_servico

        linhas = solicitacoes.map do |s|
          trechos = s.servicos
          [ s.codigo, s.nome_do_tipo, s.nome_do_status, s.solicitante_nome, s.unidade_nome.to_s, I18n.l(s.saida_em, format: "%d/%m/%Y %H:%M"),
            s.destinos.map(&:nome).join("; "), trechos.map(&:motorista_nome).uniq.join(", "), trechos.map(&:placa).uniq.join(", "),
            trechos.sum { |trecho| trecho.km_rodados.to_i } ]
        end
        por_status = solicitacoes.map(&:nome_do_status).tally
        [ [ "Código", "Tipo", "Status", "Solicitante", "Unidade", "Saída", "Destinos", "Motoristas", "Veículos", "Km" ], linhas,
          { "Solicitações" => linhas.size }.merge(por_status) ]
      end
    end
  end
end
