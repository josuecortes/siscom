module Transporte
  # A operação abre uma solicitação em nome de outra pessoa (como no seed) e, se preciso, fora do
  # prazo de antecedência ("fora do padrão"). A pessoa passa a ser a dona; fica registrado quem abriu.
  class SolicitacoesParaOutroController < BaseController
    before_action { pode!(Transporte::Solicitacoes::Abrir::PERMISSAO_DA_OPERACAO) }

    def new
      @solicitante = pessoa(params.dig(:solicitacao, :solicitante_id))
      @solicitacao = Transporte::Solicitacao.new(tipo: "normal")
      @solicitacao.passageiros.build
      @solicitacao.destinos.build
      preparar_formulario
    end

    def create
      dados = params.fetch(:solicitacao, {})
      @solicitante = pessoa(dados[:solicitante_id])
      atributos = dados.permit(*Transporte::Solicitacoes::Abrir::CAMPOS, passageiros: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_PASSAGEIRO ],
                                                                      destinos: [ Transporte::Solicitacoes::Abrir::CAMPOS_DO_DESTINO ])
      resultado = Transporte::Solicitacoes::Abrir.call(user: @solicitante, aberto_por: current_user, fora_do_padrao: dados[:fora_do_padrao] == "1", atributos: atributos)
      @solicitacao = resultado.objeto

      if resultado.sucesso?
        redirect_to transporte_operacao_path(@solicitacao), status: :see_other, notice: "Solicitação #{@solicitacao.codigo} aberta em nome de #{@solicitante.nome}."
      else
        @solicitacao.passageiros.build if @solicitacao.passageiros.empty?
        @solicitacao.destinos.build if @solicitacao.destinos.empty?
        preparar_formulario
        render :new, status: :unprocessable_content
      end
    end

    # Opções do campo de busca da pessoa (JSON).
    def pessoas
      termo = params[:q].to_s.squish
      ativos = ::User.ativos.where.not(id: current_user.id).order(:nome, :id)
      achados = termo.length >= 3 ? ativos.buscar(termo) : ativos.none
      todas = achados.none?
      escolhidos = todas ? ativos : achados

      render json: { opcoes: escolhidos.limit(50).map { |user| { valor: user.id, rotulo: user.nome, subtitulo: user.email } }, todas: todas,
                     restantes: [ escolhidos.count - 50, 0 ].max }
    end

    private

    def pessoa(id) = ::User.ativos.where.not(id: current_user.id).find_by(id: id)

    def preparar_formulario
      @lotacoes = @solicitante ? Rh::Api.lotacoes_ativas(@solicitante) : []
      @configuracao = Transporte::Configuracao.atual
    end
  end
end
