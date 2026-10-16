# Página "Acompanhamento" do menu (TI e Transporte): explica o painel de TV, diz se ele está ligado, quem tem a senha
# (os administradores do módulo) e tem o botão para abri-lo. Quem inclui define:
#   permissao_do_sobre   -> "ti.acompanhamento.ver"
#   textos_do_sobre      -> { modulo:, caminho_do_painel:, colunas: [[titulo, explicação]], onde_ligar:, configuracao: }
module SobreOPainelDeTv
  extend ActiveSupport::Concern

  included do
    before_action { pode!(permissao_do_sobre) }
  end

  def show
    @textos = textos_do_sobre
    @ligado = @textos[:configuracao].painel_ligado?
    modulo = @textos[:modulo_chave]
    @administradores = ::User.ativos.where(id: Core::Api.ids_dos_usuarios_com_papel(modulo: modulo, papeis: %w[admin])).order(:nome).pluck(:nome)
    @atualiza_a_cada = PainelDeTv::ATUALIZA_A_CADA
    @validade_em_horas = (PainelDeTv::VALIDADE / 1.hour).to_i
    render "compartilhado/painel_tv/sobre"
  end
end
