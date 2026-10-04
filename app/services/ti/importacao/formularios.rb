module Ti
  module Importacao
    # Formulários das requisições especiais do siscom antigo (validações de requisicao_ti.rb e
    # campos de requisicao_tis/_form), reescritos como campos dinâmicos. Nome da solicitação
    # antiga => lista de campos. O que não está aqui recebe só "Observações".
    module Formularios
      PERFIS_PRODOC = [
        "RESPONSÁVEL POR UNIDADE - chefe de unidade: cria, envia e distribui documentos; recebe e envia documentos sigilosos",
        "AUXILIAR DO RESPONSÁVEL - mesmas funções do responsável, menos o envio de documentos restritos",
        "CONSULTA/RASCUNHO - cria rascunhos, visualiza e recebe documentos distribuídos pelo chefe",
        "ANALISTA - responde às solicitações do coordenador; não envia documentos"
      ].freeze
      PERMISSOES_DRIVE = [
        "Leitor: pode apenas visualizar documentos e pastas",
        "Comentador: pode visualizar e comentar em documentos já existentes",
        "Colaborador: pode criar pastas, enviar arquivos, criar e renomear documentos e pastas"
      ].freeze

      NOME = { rotulo: "Nome completo", obrigatorio: true, ajuda: "Nome do servidor para quem é o pedido." }.freeze
      EMAIL = { rotulo: "E-mail", obrigatorio: true, ajuda: "E-mail (ou sugestão de e-mail) do servidor." }.freeze
      FUNCAO = { rotulo: "Função", tipo: "busca", fonte: "rh_funcoes", obrigatorio: true }.freeze
      UNIDADE = { rotulo: "Unidade", tipo: "busca", fonte: "rh_unidades", obrigatorio: true }.freeze
      DESTINO = { rotulo: "Unidade/pasta de destino", obrigatorio: true, exemplo: "SIGLA - Nome da unidade" }.freeze
      PERFIL = { rotulo: "Perfil", tipo: "selecao", opcoes: PERFIS_PRODOC, obrigatorio: true }.freeze
      INICIO = { rotulo: "Início do período", tipo: "data", obrigatorio: true }.freeze
      FIM = { rotulo: "Fim do período", tipo: "data", obrigatorio: true }.freeze
      NOMEACAO = { rotulo: "Carta de apresentação ou decreto de nomeação", tipo: "arquivo", obrigatorio: true, ajuda: "Arquivo de até 1 MB." }.freeze
      PRODOC = { rotulo: "Documento do Prodoc", tipo: "arquivo", obrigatorio: true }.freeze
      OBSERVACOES = { rotulo: "Observações", tipo: "texto_longo" }.freeze
      DESCRICAO = { rotulo: "Observações", tipo: "texto_longo", obrigatorio: true, ajuda: "Descreva o problema ou o que precisa." }.freeze

      POR_SOLICITACAO = {
        "PRODOC - CADASTRO" => [
          NOME, EMAIL, { rotulo: "CPF", mascara: "cpf", obrigatorio: true }, { rotulo: "RG", obrigatorio: true },
          { rotulo: "Data de nascimento", tipo: "data", obrigatorio: true }, { rotulo: "Celular", mascara: "celular", obrigatorio: true },
          { rotulo: "Cargo", tipo: "busca", fonte: "rh_cargos", obrigatorio: true }, FUNCAO,
          { rotulo: "Estado", obrigatorio: true }, { rotulo: "Município", obrigatorio: true }, PERFIL, DESTINO, NOMEACAO
        ],
        "PRODOC - SUBSTITUIÇÃO" => [ NOME, EMAIL, INICIO, FIM ],
        "PRODOC - RETIRADA" => [ NOME, EMAIL ],
        "PRODOC - TROCAR SENHA" => [ NOME, EMAIL ],
        "PRODOC - ALTERAR PERFIL" => [ NOME, EMAIL, PERFIL ],
        "PRODOC - LIBERAR ACESSO" => [ NOME, EMAIL, FUNCAO, PERFIL, INICIO, FIM ],
        "PRODOC - CADASTRO DE INSTITUIÇÃO EXTERNA" => [
          { rotulo: "Nome da instituição externa", obrigatorio: true }, { rotulo: "Sigla da instituição externa", obrigatorio: true },
          { rotulo: "Nome da unidade organizacional externa", obrigatorio: true }, { rotulo: "Sigla da unidade organizacional externa", obrigatorio: true },
          { rotulo: "Responsável da instituição externa", obrigatorio: true }, { rotulo: "Cargo do responsável", obrigatorio: true },
          { rotulo: "Pronome do responsável", obrigatorio: true }, { rotulo: "CEP da instituição externa", mascara: "cep", obrigatorio: true },
          { rotulo: "Cidade da instituição externa", obrigatorio: true }, { rotulo: "UF da instituição externa", obrigatorio: true }
        ],
        "PRODOC - PROBLEMAS" => [ DESCRICAO ],
        "PRODOC - TREINAMENTO" => [ DESCRICAO ],
        "WEBMAIL - CADASTRO" => [ NOME, FUNCAO, EMAIL, UNIDADE ],
        "WEBMAIL - TROCAR SENHA" => [ NOME, EMAIL ],
        "WEBMAIL - PROBLEMAS" => [ DESCRICAO ],
        "SISCOM - CADASTRO" => [ NOME, FUNCAO, UNIDADE, EMAIL, NOMEACAO ],
        "SISCOM - TROCAR SENHA" => [ NOME, EMAIL ],
        "SISCOM - PROBLEMAS" => [ DESCRICAO ],
        "SIGDOC - SOLICITAR PERMISSÃO DE ACESSO" => [
          NOME, EMAIL, UNIDADE, { rotulo: "Celular", mascara: "celular", obrigatorio: true },
          { rotulo: "NAE da escola", ajuda: "Preencha se o pedido for para uma escola." }
        ],
        "SIGDOC - DESABILITAR PERMISSÃO" => [ NOME, EMAIL ],
        "SIGDOC - PROBLEMAS" => [ DESCRICAO ],
        "SIGDOC - TREINAMENTO" => [ DESCRICAO ],
        "ADICIONAR USUARIO NO DOMINIO" => [ NOME, UNIDADE, DESTINO, NOMEACAO ],
        "ACESSO A PASTA COMPARTILHADA" => [ NOME, UNIDADE, DESTINO ],
        "GOOGLE DRIVE - PERMISSÃO DE ACESSO" => [
          NOME, EMAIL, DESTINO, { rotulo: "Permissão na pasta do Google Drive", tipo: "selecao", opcoes: PERMISSOES_DRIVE, obrigatorio: true }, PRODOC
        ],
        "GOOGLE DRIVE – SOLICITAR EXCLUSÃO DE DOCUMENTOS" => [ { rotulo: "Nome do arquivo a ser excluído", obrigatorio: true }, DESTINO, PRODOC ]
      }.freeze

      module_function

      # Campos da solicitação antiga `nome`; sempre termina com "Observações".
      def para(nome)
        campos = POR_SOLICITACAO.fetch(nome.to_s.squish.upcase, [])
        campos.any? { |campo| campo[:rotulo] == OBSERVACOES[:rotulo] } ? campos : campos + [ OBSERVACOES ]
      end
    end
  end
end
