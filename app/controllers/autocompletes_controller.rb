class AutocompletesController < ApplicationController
  before_action :authenticate_user!

  def problemas_ti
    problemas = build_problemas_for(current_user)
    term = params[:term]&.downcase
    
    if term.present?
      problemas = problemas.select { |p| p[0].downcase.include?(term) }
    end
    
    render json: problemas.map { |p| { id: p[1], value: p[0] } }
  end

  def cargos
    term = params[:term]&.downcase
    cargos = Cargo.order(nome: :asc)
    
    if term.present?
      cargos = cargos.where("LOWER(nome) LIKE ?", "%#{term}%")
    end
    
    cargos = cargos.all.map { |c| [c.nome, c.id] }
    render json: cargos.map { |c| { id: c[1], value: c[0] } }
  end

  def funcoes
    term = params[:term]&.downcase
    funcoes = if current_user.has_role? :master
      Funcao.order(nome: :asc)
    elsif current_user.has_role? :admin
      Funcao.where("nome <> ?", 'Master').order(nome: :asc)
    else
      Funcao.where("nome <> ? and nome <> ?", 'master', 'admin').order(nome: :asc)
    end

    if term.present?
      funcoes = funcoes.where("LOWER(nome) LIKE ?", "%#{term}%")
    end

    funcoes = funcoes.all
    render json: funcoes.map { |f| { id: f.id, value: f.nome } }
  end

  def unidades
    term = params[:term]&.downcase
    unidades = if current_user.has_role?(:admin) || current_user.has_role?(:master)
      Unidade.order(nome: :asc)
    else
      Unidade.order(nome: :asc).where(id: current_user.unidade_id)
    end

    if term.present?
      unidades = unidades.where("LOWER(nome) LIKE ? OR LOWER(sigla) LIKE ?", "%#{term}%", "%#{term}%")
    end

    unidades = unidades.all
    render json: unidades.map { |u| { id: u.id, value: u.sigla_nome } }
  end

  def estados
    term = params[:term]&.downcase
    estados = ['Amapá']
    
    if term.present?
      estados = estados.select { |e| e.downcase.include?(term) }
    end
    
    render json: estados.map { |e| { value: e } }
  end

  def municipios
    term = params[:term]&.downcase
    municipios = ['Amapá', 'Calçoene', 'Cutias', 'Ferreira Gomes', 'Itaubal', 'Laranjal do Jarí', 'Macapá', 'Mazagão', 'Oiapoque', 'Pedra Branca do Amapari', 'Porto Grande', 'Pracuúba', 'Santana', 'Serra do Navio', 'Tartarugalzinho', 'Vitória do Jari']
    
    if term.present?
      municipios = municipios.select { |m| m.downcase.include?(term) }
    end
    
    render json: municipios.map { |m| { value: m } }
  end

  def permissoes_drive
    term = params[:term]&.downcase
    permissoes = ['Leitor: Pode apenas visualizar documentos e pastas.', 'Comentador: Pode visualizar e comentar em documentos já existentes.', 'Colaborador: Pode criar novas pastas, realizar uploads de pastas e arquivos, criar novos documentos, renomear documentos e pastas.']
    
    if term.present?
      permissoes = permissoes.select { |p| p.downcase.include?(term) }
    end
    
    render json: permissoes.map { |p| { value: p } }
  end

  def perfis
    term = params[:term]&.downcase
    perfis = ['RESPONSÁVEL POR UNIDADE - usuário chefe de unidade: cria, faz envio, distribuições de documentos e recebe e envia documentos sigilosos. Acesso a aba de Documentos e Processo.', 'AUXILIAR DO RESPONSÁVEL - auxilia o chefe dentro da unidade: possui as mesmas funções do Reponsável de unidade com exceção de envio de documentos restritos. Acesso a aba de documentos.', 'CONSULTA/RASCUNHO - Usuários que tem a opção apenas de criar rascunho, visualizam e recebe documentos distribuídos pelo chefe, usuário mais utilizado apenas para consulta de documentos dentro da unidade. Acesso a aba de documentos', 'ANALISTA - Usuários responsáveis por apenas responder as solicitações do coordenador, não fazem envio de documento, receber distribuições da coordenação e pode devolver a distribuição (cadastra despacho quando solicitado por distribuição) pode fazer a criação de documentos. Acesso a aba de documentos.']
    
    if term.present?
      perfis = perfis.select { |p| p.downcase.include?(term) }
    end
    
    render json: perfis.map { |p| { value: p } }
  end

  private
  def build_problemas_for(user)
    if user.has_role?(:req_serv_ti_sis)
      if user.pode_solicitar_requisicao_ti_normal
        if user.unidade.tipo_unidade.nome == 'ESCOLA'
          ProblemaTi.where("(tipo_problema_ti_id = ? OR tipo_problema_ti_id = ?) AND status != ?", 3, 6, false)
                    .order(nome: :asc)
                    .map { |p| [p.nome, p.id] }
        else
          ProblemaTi.where("tipo_problema_ti_id <> ? AND status != ?", 6, false)
                    .order(nome: :asc)
                    .map { |p| [p.nome, p.id] }
        end
      else
        ProblemaTi.where("(tipo_problema_ti_id = ? OR tipo_problema_ti_id = ?) AND status != ?", 3, 5, false)
                  .order(nome: :asc)
                  .map { |p| [p.nome, p.id] }
      end
    elsif user.has_role?(:req_serv_ti)
      ProblemaTi.where("tipo_problema_ti_id <> ? AND tipo_problema_ti_id <> ? AND status != ?", 3, 6, false)
                .order(nome: :asc)
                .map { |p| [p.nome, p.id] }
    else
      []
    end
  end
end


