module Ti
  # TI → Administração: a mesma tela serve aos três itens simples do catálogo (categorias de
  # solicitação, perfis de abertura e grupos técnicos). O item vem da rota.
  class CatalogoController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action :carregar_tabela
    before_action :carregar_registro, only: %i[edit update ativar desativar]

    helper_method :caminho_da_lista, :caminho_do_registro, :caminho_novo, :caminho_editar, :caminho_de_status

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo]) || "todos" }
      registros = @modelo.ordenados
      registros = registros.buscar(@filtros[:q]) if @filtros[:q].present?
      registros = registros.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      @pagy, @registros = pagy(:offset, registros, limit: POR_PAGINA)
      @contagens = contagens_de_vinculos(@registros.map(&:id))
    end

    def new
      @registro = @modelo.new
    end

    def create
      salvar(@modelo.new, :new, "#{@tabela.singular.upcase_first} #{@tabela.feminino? ? 'criada' : 'criado'} com sucesso.")
    end

    def edit
    end

    def update
      salvar(@registro, :edit, "#{@tabela.singular.upcase_first} #{@tabela.feminino? ? 'atualizada' : 'atualizado'} com sucesso.")
    end

    def ativar = alterar_status(true)
    def desativar = alterar_status(false)

    private

    def carregar_tabela
      @tabela = Ti::Catalogo.buscar!(params[:tabela])
      @modelo = @tabela.modelo
    end

    # Quantos usuários cada perfil de abertura tem e quantos membros cada grupo técnico tem.
    def contagens_de_vinculos(ids)
      case @tabela.chave
      when "perfis_abertura"
        Ti::PerfilUsuario.where(perfil_abertura_id: ids).group(:perfil_abertura_id).count
                         .merge(Ti::PerfilAbertura.where(id: ids, padrao: true).pluck(:id).index_with { "Todos" })
      when "grupos_tecnicos" then Ti::MembroGrupo.where(grupo_tecnico_id: ids).group(:grupo_tecnico_id).count
      else {}
      end
    end

    def carregar_registro
      @registro = @modelo.find(params[:id])
    end

    def salvar(registro, tela, aviso)
      resultado = Ti::Catalogo::Salvar.call(registro: registro, atributos: params.expect(registro: %i[nome descricao permite_autoatribuicao padrao]), salvo_por: current_user)
      @registro = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: caminho_da_lista)
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo)
      resultado = Ti::Catalogo::AlterarStatus.call(registro: @registro, ativo: ativo, alterado_por: current_user)
      feito = ativo ? (@tabela.feminino? ? "ativada" : "ativado") : (@tabela.feminino? ? "desativada" : "desativado")
      opcoes = resultado.sucesso? ? { notice: "#{@tabela.singular.upcase_first} #{feito} com sucesso." } : { alert: resultado.mensagem_de_erro }

      redirect_to caminho_da_lista, status: :see_other, **opcoes
    end

    def caminho_da_lista(**parametros) = public_send("ti_#{@tabela.chave}_path", **parametros)
    def caminho_do_registro(registro) = public_send("ti_#{@tabela.chave.singularize}_path", registro)
    def caminho_novo = public_send("new_ti_#{@tabela.chave.singularize}_path")
    def caminho_editar(registro) = public_send("edit_ti_#{@tabela.chave.singularize}_path", registro)
    def caminho_de_status(registro, acao) = public_send("#{acao}_ti_#{@tabela.chave.singularize}_path", registro)
  end
end
