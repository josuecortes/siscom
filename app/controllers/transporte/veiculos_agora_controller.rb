module Transporte
  # Transporte → Veículos agora: quais veículos ativos estão livres e quais estão em serviço, com o
  # motorista e as solicitações. É calculado pelos serviços em andamento (não há entrada e saída
  # manuais como no "pátio" do siscom antigo).
  class VeiculosAgoraController < BaseController
    before_action { pode!(Transporte::Solicitacoes::Reagendar::PERMISSAO) }

    def show
      abertos = Transporte::Servico.abertos.includes(:solicitacao).order(:iniciado_em, :id).group_by(&:veiculo_id)
      veiculos = Transporte::Veiculo.ativo.ordenados.to_a
      @em_servico = veiculos.select { |veiculo| abertos.key?(veiculo.id) }.map { |veiculo| [ veiculo, abertos[veiculo.id] ] }
      @livres = veiculos.reject { |veiculo| abertos.key?(veiculo.id) }
    end
  end
end
