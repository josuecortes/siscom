# Tela Início: saudação, o que precisa da atenção da pessoa (em todos os módulos), atalhos, o que está em andamento,
# a operação de quem trabalha na TI ou no Transporte e links úteis. Cada módulo informa o seu pedaço pela própria Api.
class InicioController < ApplicationController
  # Links úteis (abrem em nova aba). Os manuais e vídeos do siscom antigo ficaram de fora: o sistema mudou
  # (decisão do Josue, 2026-10-16); ficam os de outros sistemas.
  LINKS_UTEIS = [
    { titulo: "Manual do PRODOC", detalhe: "PDF", arquivo: "manual-prodoc.pdf", icone: :description },
    { titulo: "Como fazer upload e assinatura no SIGDOC", detalhe: "Vídeo", url: "https://www.youtube.com/watch?v=aFPW_v3PBM4", icone: :media_play },
    { titulo: "Como acessar o webmail institucional", detalhe: "Vídeo", url: "https://www.youtube.com/watch?v=vQI_Hmqemjg", icone: :media_play },
    { titulo: "Como acessar o servidor de arquivos", detalhe: "Vídeo", url: "https://www.youtube.com/watch?v=tP1-pNXktww", icone: :media_play }
  ].freeze

  def index
    @unidade = Rh::Api.unidade_atual(current_user)
    # Só os módulos que existem no catálogo (config/modulos); cada um decide o que a pessoa vê.
    apis = { "ti" => Ti::Api, "transporte" => Transporte::Api, "equipamentos" => Equipamentos::Api }
    modulos = apis.filter_map { |chave, api| api.resumo_do_inicio(current_user) if Core::Api.modulo(chave) }
    @atalhos = modulos.flat_map { |modulo| modulo[:atalhos] }
    @atencao = (avisos_do_core + modulos.flat_map { |modulo| modulo[:atencao] }).select { |item| item[:quantidade].positive? }
    @andamento = modulos.filter_map { |modulo| modulo[:andamento] }
    @operacao = modulos.filter_map { |modulo| modulo[:operacao] }
    @canais_da_operacao = [ ("ti_operacao" if @operacao.any? { |bloco| bloco[:titulo].include?("TI") }),
                            ("transporte_operacao" if @operacao.any? { |bloco| bloco[:titulo].include?("Transporte") }) ].compact
  end

  private

  def avisos_do_core
    [ { titulo: "Mensagens não lidas", detalhe: "Nas conversas dos seus chamados e solicitações.", quantidade: Core::Participante.nao_lidas_de(current_user),
        caminho: conversas_path, tom: "info" },
      { titulo: "Notificações não lidas", detalhe: "Avisos do sistema para você.", quantidade: current_user.notificacoes.nao_lidas.count,
        caminho: notificacoes_path, tom: "info" } ]
  end
end
