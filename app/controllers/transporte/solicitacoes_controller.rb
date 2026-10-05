module Transporte
  # Minha área → Solicitações de transporte (porta de transport-requests-module.tsx, visão do
  # requisitante): o solicitante abre e acompanha os próprios pedidos.
  class SolicitacoesController < BaseController
    POR_PAGINA = 20
    # Abas da lista do solicitante (como no seed: em serviço junta "em serviço" e "aguardando busca").
    ABAS = { "solicitada" => [ "Solicitadas", %w[solicitada] ], "aprovada" => [ "Aprovadas", %w[aprovada] ], "em_servico" => [ "Em serviço", %w[em_servico busca] ],
             "concluida" => [ "Concluídas", %w[concluida] ], "cancelada" => [ "Canceladas", %w[cancelada] ] }.freeze

    before_action { pode!(Transporte::Solicitacoes::Abrir::PERMISSAO) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(ABAS.keys) || "solicitada" }
      solicitacoes = Transporte::Solicitacao.where(solicitante: current_user)
      solicitacoes = solicitacoes.buscar(@filtros[:q]) if @filtros[:q].present?
      por_status = solicitacoes.group(:status).count
      @contagens = ABAS.transform_values { |(_, status)| por_status.values_at(*status).compact.sum }
      @pagy, @solicitacoes = pagy(:offset, solicitacoes.where(status: ABAS.dig(@filtros[:status], 1)).order(:saida_em, :id).includes(:destinos), limit: POR_PAGINA)
    end

    def show
      @solicitacao = Transporte::Solicitacao.where(solicitante: current_user).or(Transporte::Solicitacao.where(aberto_por: current_user)).find(params[:id])
    end

    def new
      @solicitacao = Transporte::Solicitacao.new(tipo: "normal")
      @solicitacao.passageiros.build
      @solicitacao.destinos.build
      preparar_formulario
    end

    def create
      atributos = params.fetch(:solicitacao, {}).permit(*Transporte::Solicitacoes::Abrir::CAMPOS,
                                                         passageiros: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_PASSAGEIRO ],
                                                         destinos: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_DESTINO ])
      resultado = Transporte::Solicitacoes::Abrir.call(user: current_user, atributos: atributos)
      @solicitacao = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: "Solicitação #{@solicitacao.codigo} aberta com sucesso.", voltar_para: transporte_solicitacoes_path)
      else
        @solicitacao.passageiros.build if @solicitacao.passageiros.empty?
        @solicitacao.destinos.build if @solicitacao.destinos.empty?
        preparar_formulario
        render :new, status: :unprocessable_content
      end
    end

    private

    def preparar_formulario
      @lotacoes = Rh::Api.lotacoes_ativas(current_user)
      @configuracao = Transporte::Configuracao.atual
    end
  end
end
