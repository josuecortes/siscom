module Transporte
  # O motorista inicia e finaliza os trechos do serviço, pelos botões da linha na Operação.
  class ServicosController < BaseController
    before_action { pode!(Transporte::Servicos::Iniciar::PERMISSAO) }
    before_action(except: :veiculos) { @solicitacao = Transporte::Operacao.do_motorista(current_user).find(params[:id]) }

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
      responder Transporte::Servicos::Finalizar.call(solicitacao: @solicitacao, ator: current_user, odometro: params[:odometro], observacao: params[:observacao],
                                                      anexos: params[:anexos]),
                :fim, "Trecho finalizado."
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

    # Outras solicitações que podem ir na mesma viagem (mesma etapa, sem serviço em andamento).
    def carregar_candidatas
      mesma_etapa = Transporte::Solicitacao.where(status: @solicitacao.status).where.not(id: Transporte::Servico.abertos.select(:solicitacao_id))
      @candidatas = mesma_etapa.where.not(id: @solicitacao.id).includes(:destinos).order(:saida_em, :id).limit(30)
    end

    def responder(resultado, tela, aviso)
      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: transporte_operacao_index_path)
      else
        @erro = resultado.mensagem_de_erro
        carregar_candidatas if tela == :inicio
        render tela, status: :unprocessable_content
      end
    end
  end
end
