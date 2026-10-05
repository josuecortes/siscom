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

    # --- Chamados de TI e requisições de transporte antigos (para a migração para os módulos novos) ---
    # Tudo como hashes com chaves em símbolo, em lotes, na ordem do id antigo.

    def cada_requisicao_de_ti(&) = em_lotes(RequisicaoTi, &)
    def total_de_requisicoes_de_ti = RequisicaoTi.count

    # { id da requisição => [mensagens em ordem] }, só das requisições pedidas.
    def mensagens_das_requisicoes_de_ti(ids)
      Mensagem.where(requisicao_ti_id: ids).order(:id).map { |mensagem| mensagem.attributes.symbolize_keys }.group_by { |mensagem| mensagem[:requisicao_ti_id] }
    end

    def cada_requisicao_de_transporte(&) = em_lotes(RequisicaoTransporte, &)
    def total_de_requisicoes_de_transporte = RequisicaoTransporte.count

    def passageiros_das_requisicoes(ids) = filhos(Passageiro, ids)
    def destinos_das_requisicoes(ids) = filhos(Destino, ids)

    # Serviços antigos, já com o nome do motorista e a placa (os cadastros antigos não foram migrados).
    def servicos_das_requisicoes(ids)
      motoristas = Motorista.pluck(:id, :nome).to_h
      veiculos = Veiculo.pluck(:id, :placa).to_h
      filhos(ServicoTransporte, ids).transform_values do |servicos|
        servicos.map { |servico| servico.merge(motorista_nome: motoristas[servico[:motorista_id]], placa: veiculos[servico[:veiculo_id]]) }
      end
    end

    # Anexos (Active Storage) de registros antigos: { id do registro => [{ nome:, blob_id: }] }.
    # `tipo` é o nome da classe antiga gravado em record_type ("RequisicaoTi", "Mensagem"…).
    def anexos(tipo, ids)
      ActiveStorage::Attachment.where(record_type: tipo, record_id: ids).order(:id).pluck(:record_id, :name, :blob_id)
                               .group_by(&:first).transform_values { |linhas| linhas.map { |_, nome, blob_id| { nome:, blob_id: } } }
    end

    def em_lotes(modelo)
      modelo.in_batches(of: 500) { |lote| yield lote.order(:id).map { |registro| registro.attributes.symbolize_keys } }
    end

    def filhos(modelo, ids)
      modelo.where(requisicao_transporte_id: ids).order(:id).map { |registro| registro.attributes.symbolize_keys }.group_by { |registro| registro[:requisicao_transporte_id] }
    end

    # { "master" => 1, "admin" => 19, ... }
    def contagem_de_papeis
      Papel.where(resource_type: nil)
           .joins("LEFT JOIN users_roles ON users_roles.role_id = roles.id")
           .group("roles.name").count("users_roles.user_id")
    end
  end
end
