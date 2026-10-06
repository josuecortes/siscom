module Equipamentos
  # Minha área → Meus equipamentos: o que tenho para receber, os empréstimos para aceitar, o que está comigo
  # emprestado (para devolver) e as devoluções para eu receber. É de todo usuário.
  # O administrador de Equipamentos pode fazer essas ações em nome da pessoa (fica registrado).
  class RecebimentosController < BaseController
    before_action { pode!("equipamentos.receber") }
    before_action(except: :index) { @envio = meus_envios.find(params[:id]) }
    before_action(only: %i[termo devolucao recebimento_da_devolucao]) { abrir_sobre(volta) }
    helper_method :volta

    def index
      meus = Equipamentos::Movimentacao.em_andamento.where(responsavel: current_user).includes(itens: :item).order(:created_at, :id)
      @para_receber = meus.definitivas.select { |envio| envio.itens.any?(&:pendente?) }
      @para_aceitar = meus.emprestimos.select { |envio| envio.itens.any?(&:pendente?) }
      @comigo = meus.emprestimos.select { |envio| envio.itens.any? { |linha| linha.emprestado? || linha.devolucao_pendente? } }
      @devolucoes = Equipamentos::Movimentacao.em_andamento.where(id: Equipamentos::ItemMovimentacao.devolucao_pendente.where(devolver_para: current_user).select(:movimentacao_id))
                                              .includes(itens: :item).order(:created_at, :id)
    end

    def receber
      operar "receber_item", "Recebimento registrado.", item_id: params[:item_id].presence
    end

    def termo
      @texto = @envio.aceita? ? @envio.termo : Equipamentos::Envios::Termo.texto(@envio)
    end

    def aceitar
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "aceitar", ator: current_user), :termo, "Termo aceito: os equipamentos estão sob a sua responsabilidade."
    end

    def devolucao
    end

    def devolver
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "devolver", ator: current_user, para_id: params[:para_id]), :devolucao,
                "Devolução iniciada: a pessoa indicada foi avisada e precisa confirmar o recebimento."
    end

    def recebimento_da_devolucao
    end

    def receber_devolucao
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "receber_devolucao", ator: current_user, observacao: params[:observacao]), :recebimento_da_devolucao,
                "Devolução recebida: o equipamento voltou para a unidade."
    end

    private

    # Os envios em que sou quem recebe, ou quem recebe a devolução; o administrador, todos.
    def meus_envios
      return Equipamentos::Movimentacao.all if Equipamentos::Acesso.pode?(current_user, Equipamentos::Acesso::ADMINISTRAR)

      Equipamentos::Movimentacao.where(responsavel: current_user)
                                .or(Equipamentos::Movimentacao.where(id: Equipamentos::ItemMovimentacao.where(devolver_para: current_user).select(:movimentacao_id)))
    end

    def volta = params[:voltar] == "lista" ? (@envio.emprestimo? ? equipamentos_emprestimos_path : equipamentos_movimentacoes_path) : equipamentos_recebimentos_path

    def operar(acao, aviso, **outros)
      resultado = Equipamentos::Envios::Operar.call(envio: @envio, acao: acao, ator: current_user, **outros)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }
      redirect_to volta, status: :see_other, **opcoes
    end

    def responder(resultado, tela, aviso)
      return concluir_painel(aviso: aviso, voltar_para: volta) if resultado.sucesso?

      @erro = resultado.mensagem_de_erro
      @texto = @envio.aceita? ? @envio.termo : Equipamentos::Envios::Termo.texto(@envio)
      render tela, status: :unprocessable_content
    end
  end
end
