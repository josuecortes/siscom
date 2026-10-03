module Core
  # Administração → Fontes de referência (porta de core-reference-sources-module.tsx).
  class FontesReferenciaController < BaseController
    POR_PAGINA = 20

    before_action { pode!("core.fontes_referencia.gerenciar") }
    before_action :carregar_fonte, only: %i[edit update ativar desativar]

    def index
      FontesReferencia::Publicar.call
      @busca = params[:q].to_s.strip
      fontes = Core::FonteReferencia.ordenadas
      fontes = fontes.buscar(@busca) if @busca.present?
      @pagy, @fontes = pagy(:offset, fontes, limit: POR_PAGINA)
    end

    def new
      @fonte = Core::FonteReferencia.new(tipos_de_campo: Core::FonteReferencia::TIPOS_DE_CAMPO.keys)
      aplicar_padroes_da_entidade(params[:entidade])
    end

    def create
      salvar(Core::FonteReferencia.new, :new, "Fonte criada com sucesso.")
    end

    def edit
    end

    def update
      salvar(@fonte, :edit, "Fonte atualizada com sucesso.")
    end

    def ativar = alterar_status(true, "Fonte ativada com sucesso.")
    def desativar = alterar_status(false, "Fonte desativada com sucesso.")

    private

    def carregar_fonte
      @fonte = Core::FonteReferencia.find(params[:id])
    end

    def atributos
      params.expect(fonte: [ :nome, :descricao, :entidade_completa, :campo_rotulo, :campo_valor, :campo_subtitulo,
                             { campos_busca: [], tipos_de_campo: [] } ])
    end

    def salvar(fonte, tela, aviso)
      resultado = FontesReferencia::Salvar.call(fonte: fonte, atributos: atributos, salvo_por: current_user)
      @fonte = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: core_fontes_referencia_path)
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo, aviso)
      resultado = FontesReferencia::AlterarStatus.call(fonte: @fonte, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to core_fontes_referencia_path, status: :see_other, **opcoes
    end

    # Ao escolher a entidade no formulário de nova fonte, preenche os campos com o padrão dela.
    def aplicar_padroes_da_entidade(valor)
      modulo, entidade = valor.to_s.split(":", 2)
      definicao = FontesReferencia::Entidades.buscar(modulo, entidade)
      return unless definicao

      @fonte.assign_attributes(modulo: modulo, entidade: entidade, nome: definicao.nome, descricao: definicao.descricao,
                               campo_rotulo: definicao.campo_rotulo, campo_valor: definicao.campo_valor,
                               campo_subtitulo: definicao.campo_subtitulo, campos_busca: definicao.campos_busca)
    end
  end
end
