module Transporte
  # Transporte → Meus serviços (visão do motorista de transport-requests-module.tsx): o que está
  # para sair, as buscas, o que ele está fazendo e o que já fez; inicia e finaliza os trechos.
  class ServicosController < BaseController
    POR_PAGINA = 20
    ABAS = { "saidas" => "Para sair", "buscas" => "Buscas", "andamento" => "Comigo agora", "feitos" => "Feitos por mim" }.freeze

    before_action { pode!(Transporte::Servicos::Iniciar::PERMISSAO) }
    before_action(except: %i[index veiculos]) { @solicitacao = visiveis.find(params[:id]) }

    def index
      @filtros = { status: params[:status].presence_in(ABAS.keys) || "saidas" }
      @contagens = ABAS.keys.index_with { |aba| da_aba(aba).count }
      @pagy, @solicitacoes = pagy(:offset, da_aba(@filtros[:status]).includes(:destinos).order(:saida_em, :id), limit: POR_PAGINA)
    end

    def show
    end

    def inicio
      carregar_candidatas
    end

    def iniciar
      responder Transporte::Servicos::Iniciar.call(solicitacao: @solicitacao, ator: current_user, veiculo_id: params[:veiculo_id], odometro: params[:odometro],
                                                      outras_ids: params[:outras_ids]),
                :inicio, "Serviço iniciado. Boa viagem!"
    end

    def fim
      @servico = @solicitacao.servico_aberto
    end

    def finalizar
      @servico = @solicitacao.servico_aberto
      responder Transporte::Servicos::Finalizar.call(solicitacao: @solicitacao, ator: current_user, odometro: params[:odometro]), :fim, "Trecho finalizado."
    end

    # Veículos ativos e livres, para o campo de busca (JSON).
    def veiculos
      termo = params[:q].to_s.squish
      livres = Transporte::Veiculo.ativo.where.not(id: Transporte::Servico.abertos.select(:veiculo_id)).ordenados
      achados = termo.length >= 3 ? livres.buscar(termo) : livres.none
      todas = achados.none?

      render json: { opcoes: (todas ? livres : achados).limit(50).map { |v| { valor: v.id, rotulo: v.descricao, subtitulo: "Odômetro: #{v.odometro_atual} km" } },
                     todas: todas, restantes: 0 }
    end

    private

    # O motorista vê o que está aprovado ou aguardando busca (para pegar) e tudo em que ele trabalhou.
    def visiveis
      Transporte::Solicitacao.where(status: %w[aprovada busca]).or(Transporte::Solicitacao.where(id: Transporte::Servico.where(motorista: current_user).select(:solicitacao_id)))
    end

    # Outras solicitações que podem ir na mesma viagem (mesma etapa, sem serviço em andamento).
    def carregar_candidatas
      @candidatas = da_aba(@solicitacao.busca? ? "buscas" : "saidas").where.not(id: @solicitacao.id).includes(:destinos).order(:saida_em, :id).limit(30)
    end

    def da_aba(aba)
      abertos = Transporte::Servico.abertos
      case aba
      when "buscas" then Transporte::Solicitacao.busca.where.not(id: abertos.select(:solicitacao_id))
      when "andamento" then Transporte::Solicitacao.where(id: abertos.where(motorista: current_user).select(:solicitacao_id))
      when "feitos" then Transporte::Solicitacao.where(id: Transporte::Servico.where(motorista: current_user).where.not(finalizado_em: nil).select(:solicitacao_id))
      else Transporte::Solicitacao.aprovada
      end
    end

    def responder(resultado, tela, aviso)
      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: transporte_servico_path(@solicitacao))
      else
        @erro = resultado.mensagem_de_erro
        carregar_candidatas if tela == :inicio
        render tela, status: :unprocessable_content
      end
    end
  end
end
