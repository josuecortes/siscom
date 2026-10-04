module Legado
  # Porta de entrada do Legado para os outros módulos (somente leitura).
  module Api
    module_function

    # Ids dos usuários que tinham o papel antigo (Rolify), ex.: "master".
    def ids_dos_usuarios_com_papel(nome) = Papel.ids_dos_usuarios(nome)

    # Dados das tabelas antigas de estrutura, como listas de hashes (para a importação do RH).
    def tipos_de_unidade = TipoUnidade.order(:id).pluck(:id, :nome).map { |id, nome| { id:, nome: } }
    def funcoes = Funcao.order(:id).pluck(:id, :nome).map { |id, nome| { id:, nome: } }
    def cargos = Cargo.order(:id).pluck(:id, :nome).map { |id, nome| { id:, nome: } }

    def unidades
      Unidade.order(:id).pluck(:id, :nome, :sigla, :tipo_unidade_id)
             .map { |id, nome, sigla, tipo_unidade_id| { id:, nome:, sigla:, tipo_unidade_id: } }
    end

    # Catálogo antigo de requisições de TI (para a carga inicial do catálogo da TI).
    def tipos_de_problema_ti
      TipoProblemaTi.order(:id).pluck(:id, :nome, :descricao).map { |id, nome, descricao| { id:, nome:, descricao: } }
    end

    def problemas_ti
      ProblemaTi.order(:id).pluck(:id, :nome, :descricao, :tipo_problema_ti_id, :status)
                .map { |id, nome, descricao, tipo_id, status| { id:, nome:, descricao:, tipo_id:, ativo: status != false } }
    end

    # Ids das unidades antigas de um tipo (ex.: "ESCOLA").
    def ids_das_unidades_do_tipo(nome) = Unidade.where(tipo_unidade_id: TipoUnidade.where(nome: nome.to_s).select(:id)).pluck(:id)

    # { "master" => 1, "admin" => 19, ... }
    def contagem_de_papeis
      Papel.where(resource_type: nil)
           .joins("LEFT JOIN users_roles ON users_roles.role_id = roles.id")
           .group("roles.name").count("users_roles.user_id")
    end
  end
end
