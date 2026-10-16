module Equipamentos
  # Opções dos campos de busca (autocomplete) de Equipamentos, em JSON.
  class OpcoesController < BaseController
    MINIMO = 3
    LIMITE = 50

    # Quem devolve um empréstimo também escolhe a pessoa da unidade de origem: as pessoas são de todo usuário.
    before_action(only: :unidades) { pode!(Equipamentos::Acesso::VER) }
    before_action(only: :pessoas) { pode!("equipamentos.receber") }

    # Unidades do RH (destino de um envio, filtro da lista).
    def unidades
      render json: Rh::Api.opcoes_de_unidades(params[:q])
    end

    # Pessoas lotadas numa unidade (quem recebe um envio).
    def pessoas
      lotados = ::User.ativos.where(id: Rh::Api.ids_dos_usuarios_da_unidade(params[:unidade_id])).where.not(id: current_user.id).order(:nome, :id)
      termo = params[:q].to_s.squish
      achados = termo.length >= MINIMO ? lotados.buscar(termo) : lotados.none
      todas = achados.none?
      escolhidos = todas ? lotados : achados

      render json: { opcoes: escolhidos.limit(LIMITE).map { |user| { valor: user.id, rotulo: user.nome, subtitulo: user.email } }, todas: todas,
                     restantes: [ escolhidos.count - LIMITE, 0 ].max }
    end
  end
end
