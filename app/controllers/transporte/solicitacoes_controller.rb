module Transporte
  # Minha área → Solicitações de transporte (porta de transport-requests-module.tsx, visão do
  # requisitante): o solicitante abre e acompanha os próprios pedidos.
  class SolicitacoesController < BaseController
    POR_PAGINA = 20
    # Abas da lista do solicitante (como no seed: em serviço junta "em serviço" e "aguardando busca").
    ABAS = { "solicitada" => [ "Solicitadas", %w[solicitada] ], "aprovada" => [ "Aprovadas", %w[aprovada] ], "reagendada" => [ "Reagendadas", %w[reagendada] ], "em_servico" => [ "Em serviço", %w[em_servico busca] ],
             "concluida" => [ "Concluídas", %w[concluida] ], "cancelada" => [ "Canceladas", %w[cancelada] ] }.freeze

    before_action { pode!(Transporte::Solicitacoes::Abrir::PERMISSAO) }
    before_action(only: %i[cancelamento cancelar edit update reagendamento responder_reagendamento]) { @solicitacao = Transporte::Solicitacao.where(solicitante: current_user).find(params[:id]) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(ABAS.keys) || "solicitada" }
      solicitacoes = Transporte::Solicitacao.where(solicitante: current_user)
      solicitacoes = solicitacoes.buscar(@filtros[:q]) if @filtros[:q].present?
      por_status = solicitacoes.group(:status).count
      @contagens = ABAS.transform_values { |(_, status)| por_status.values_at(*status).compact.sum }
      # Com busca, as abas dão lugar à aba única "Resultado", com as solicitações de todas as etapas.
      solicitacoes = solicitacoes.where(status: ABAS.dig(@filtros[:status], 1)) if @filtros[:q].blank?
      @pagy, @solicitacoes = pagy(:offset, solicitacoes.order(:saida_em, :id).includes(:destinos), limit: POR_PAGINA)
    end

    def show
      @solicitacao = Transporte::Solicitacao.where(solicitante: current_user).or(Transporte::Solicitacao.where(aberto_por: current_user)).find(params[:id])
      abrir_sobre(transporte_solicitacoes_path(status: aba_de(@solicitacao)))
    end

    def cancelamento
    end

    def cancelar
      resultado = Transporte::Solicitacoes::Cancelar.call(solicitacao: @solicitacao, ator: current_user, motivo: params[:motivo])

      if resultado.sucesso?
        concluir_painel(aviso: "Solicitação #{@solicitacao.codigo} cancelada.", voltar_para: transporte_solicitacoes_path)
      else
        @erro = resultado.mensagem_de_erro
        render :cancelamento, status: :unprocessable_content
      end
    end

    # O solicitante responde ao reagendamento proposto pela operação: aceita ou recusa (com motivo).
    def reagendamento
      abrir_sobre(transporte_solicitacoes_path(status: aba_de(@solicitacao)))
    end

    def responder_reagendamento
      aceitar = params[:resposta] == "aceitar"
      resultado = Transporte::Solicitacoes::ResponderReagendamento.call(solicitacao: @solicitacao, ator: current_user, aceitar: aceitar, motivo: params[:motivo])

      if resultado.sucesso?
        concluir_painel(aviso: (aceitar ? "Reagendamento aceito: a solicitação #{@solicitacao.codigo} segue aprovada." : "Reagendamento recusado: a solicitação #{@solicitacao.codigo} foi cancelada."),
                        voltar_para: transporte_solicitacoes_path)
      else
        @erro = resultado.mensagem_de_erro
        render :reagendamento, status: :unprocessable_content
      end
    end

    def edit
      @original = @solicitacao
      preparar_formulario
    end

    def update
      @original = @solicitacao
      resultado = Transporte::Solicitacoes::Editar.call(solicitacao: @original, ator: current_user, atributos: atributos_do_formulario)

      if resultado.sucesso?
        concluir_painel(aviso: "Solicitação #{@original.codigo} atualizada.", voltar_para: transporte_solicitacoes_path)
      else
        @solicitacao = resultado.objeto
        @solicitacao.errors.add(:base, resultado.mensagem_de_erro) if @solicitacao == @original && @solicitacao.errors.empty?
        @solicitacao.passageiros.build if @solicitacao.passageiros.empty?
        @solicitacao.destinos.build if @solicitacao.destinos.empty?
        preparar_formulario
        render :edit, status: :unprocessable_content
      end
    end

    def new
      @solicitacao = Transporte::Solicitacao.new(tipo: "normal")
      @solicitacao.passageiros.build
      @solicitacao.destinos.build
      preparar_formulario
    end

    def create
      resultado = Transporte::Solicitacoes::Abrir.call(user: current_user, atributos: atributos_do_formulario)
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

    def aba_de(solicitacao) = ABAS.find { |_, (_, status)| status.include?(solicitacao.status) }&.first

    def atributos_do_formulario
      params.fetch(:solicitacao, {}).permit(*Transporte::Solicitacoes::Abrir::CAMPOS, passageiros: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_PASSAGEIRO ],
                                                                                    destinos: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_DESTINO ])
    end

    def preparar_formulario
      @lotacoes = Rh::Api.lotacoes_ativas(current_user)
      @configuracao = Transporte::Configuracao.atual
    end
  end
end
