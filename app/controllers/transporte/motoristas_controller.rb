module Transporte
  # Transporte → Motoristas (porta de transport-drivers-module.tsx).
  class MotoristasController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Transporte::Motoristas::Salvar::PERMISSAO) }
    before_action(only: %i[edit update ativar desativar]) { @motorista = Transporte::Motorista.find(params[:id]) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo]) || "todos" }
      motoristas = Transporte::Motorista.ordenados.includes(:user)
      motoristas = motoristas.buscar(@filtros[:q]) if @filtros[:q].present?
      motoristas = motoristas.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      @pagy, @motoristas = pagy(:offset, motoristas, limit: POR_PAGINA)
    end

    def new
      @motorista = Transporte::Motorista.new
    end

    def create
      resultado = salvar(Transporte::Motorista.new)
      @motorista = resultado.objeto

      if resultado.falha?
        render :new, status: :unprocessable_content
      elsif @motorista.senha_temporaria.present?
        response.headers["Cache-Control"] = "no-store"
        render :conta_criada
      else
        concluir_painel(aviso: "Motorista cadastrado e ligado à conta que já existia com este e-mail.", voltar_para: transporte_motoristas_path)
      end
    end

    def edit
    end

    def update
      resultado = salvar(@motorista)
      @motorista = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: "Motorista atualizado com sucesso.", voltar_para: transporte_motoristas_path)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def ativar = alterar_status(true, "Motorista ativado com sucesso.")
    def desativar = alterar_status(false, "Motorista desativado com sucesso.")

    private

    def salvar(motorista)
      atributos = params.expect(motorista: Transporte::Motoristas::Salvar::CAMPOS + [ :email ])
      Transporte::Motoristas::Salvar.call(motorista: motorista, atributos: atributos, salvo_por: current_user)
    end

    def alterar_status(ativo, aviso)
      resultado = Transporte::AlterarStatus.call(registro: @motorista, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to transporte_motoristas_path, status: :see_other, **opcoes
    end
  end
end
