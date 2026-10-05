module Transporte
  # Transporte → Veículos (porta de transport-vehicles-module.tsx).
  class VeiculosController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Transporte::Veiculos::Salvar::PERMISSAO) }
    before_action(only: %i[edit update ativar desativar]) { @veiculo = Transporte::Veiculo.find(params[:id]) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo]) || "todos" }
      veiculos = Transporte::Veiculo.ordenados
      veiculos = veiculos.buscar(@filtros[:q]) if @filtros[:q].present?
      veiculos = veiculos.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      @pagy, @veiculos = pagy(:offset, veiculos, limit: POR_PAGINA)
    end

    def new
      @veiculo = Transporte::Veiculo.new
    end

    def create
      salvar(Transporte::Veiculo.new, :new, "Veículo cadastrado com sucesso.")
    end

    def edit
    end

    def update
      salvar(@veiculo, :edit, "Veículo atualizado com sucesso.")
    end

    def ativar = alterar_status(true, "Veículo ativado com sucesso.")
    def desativar = alterar_status(false, "Veículo desativado com sucesso.")

    private

    def salvar(veiculo, tela, aviso)
      resultado = Transporte::Veiculos::Salvar.call(veiculo: veiculo, atributos: params.expect(veiculo: Transporte::Veiculos::Salvar::CAMPOS), salvo_por: current_user)
      @veiculo = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: transporte_veiculos_path)
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo, aviso)
      resultado = Transporte::AlterarStatus.call(registro: @veiculo, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to transporte_veiculos_path, status: :see_other, **opcoes
    end
  end
end
