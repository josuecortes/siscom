module Ti
  module Importacao
    # Perfis de abertura da TI (decisão do Josue, 2026-10-16): quem abre o quê, a partir do siscom antigo.
    # Usado pela carga do catálogo (produção já nasce assim) e pela task `remaster:ti:perfis_de_abertura`, que
    # reorganiza um banco que já tinha os perfis da primeira carga. Idempotente: só preenche um perfil (solicitações
    # e pessoas) quando ele é criado; rodar de novo não desfaz o que foi ajustado depois nas telas.
    #
    #   SERVIDORES (padrão, vale para todos, inclusive contas novas): solicitação geral + sistemas web (não responsável)
    #   ESCOLAS - SERVIDORES          lotados em escola, sem req_serv_ti_sis
    #   ESCOLAS - GESTÃO ESCOLAR      lotados em escola, com req_serv_ti_sis
    #   ADMINISTRATIVO - SERVIDORES   fora de escola, sem req_serv_ti_sis
    #   ADMINISTRATIVO - GESTÃO       fora de escola, com req_serv_ti_sis
    #
    # Escola ou não: pela unidade da pessoa no siscom antigo (users.unidade_id → tipo de unidade ESCOLA), como o
    # siscom antigo decidia. Os perfis da primeira carga (ESCOLA, SISTEMAS WEB, UNIDADES ADMINISTRATIVAS) ficam
    # inativos; o GERAL vira SERVIDORES; o NORMAL (vazio, criado em teste) é apagado.
    class PerfisDeAbertura
      PADRAO = "SERVIDORES".freeze
      DESCRICAO_DO_PADRAO = "Vale para todos os servidores, inclusive contas novas: solicitação geral e problemas e senhas dos sistemas.".freeze
      NAO_RESPONSAVEL = "SISTEMAS WEB (NÃO RESPONSÁVEL)".freeze
      ADMINISTRATIVO = [ "REDE", "S.O.", "HARDWARE", "SUPORTE EXTERNO", NAO_RESPONSAVEL ].freeze
      # Nome => descrição, tipos antigos (categorias) que libera e de quem é: escola? e gestão (req_serv_ti_sis)?
      PERFIS = {
        "ESCOLAS - SERVIDORES" => { escola: true, gestao: false, tipos: [ NAO_RESPONSAVEL, "CONECTIVIDADE - ESCOLA" ],
                                    descricao: "Pessoas lotadas em escolas: as solicitações gerais de quem trabalha na escola." },
        "ESCOLAS - GESTÃO ESCOLAR" => { escola: true, gestao: true, tipos: [ "SISTEMAS WEB", NAO_RESPONSAVEL, "CONECTIVIDADE - ESCOLA" ],
                                        descricao: "Lotados em escolas com função de gestão (diretor, diretor adjunto, secretário escolar): também pedem cadastros e acessos nos sistemas." },
        "ADMINISTRATIVO - SERVIDORES" => { escola: false, gestao: false, tipos: ADMINISTRATIVO,
                                           descricao: "Pessoas lotadas nas unidades da SEED que não são escolas: as solicitações de quem não trabalha em escola." },
        "ADMINISTRATIVO - GESTÃO" => { escola: false, gestao: true, tipos: ADMINISTRATIVO + [ "SISTEMAS WEB" ],
                                       descricao: "Lotados em unidades administrativas com cargo de gestão (coordenador, gerente, chefe): também pedem cadastros e acessos nos sistemas." }
      }.freeze
      ANTIGOS = [ "ESCOLA", "SISTEMAS WEB", "UNIDADES ADMINISTRATIVAS" ].freeze
      DE_TESTE = "NORMAL".freeze

      Relatorio = Data.define(:criados, :pessoas, :inativados, :apagados, :padrao) do
        def to_s
          "perfis criados: #{criados.presence&.join(', ') || 'nenhum (já existiam)'}; pessoas incluídas: #{pessoas}; " \
            "inativados: #{inativados.presence&.join(', ') || 'nenhum'}; apagados: #{apagados.presence&.join(', ') || 'nenhum'}; padrão: #{padrao}"
        end
      end

      def self.call(...) = new(...).call

      # O perfil padrão, que vale para todos: acha o SERVIDORES, ou renomeia o GERAL da primeira carga, ou cria.
      def self.perfil_padrao!
        Ti::PerfilAbertura.find_by(nome: PADRAO) ||
          Ti::PerfilAbertura.find_by(nome: "GERAL", padrao: true)&.tap { |geral| geral.update!(nome: PADRAO, descricao: DESCRICAO_DO_PADRAO) } ||
          Ti::PerfilAbertura.create!(nome: PADRAO, padrao: true, descricao: DESCRICAO_DO_PADRAO)
      end

      def initialize(usuarios: ::User.ativos.where.not("email LIKE '%@siscom.dev'"))
        @usuarios = usuarios
      end

      def call
        criados = []
        pessoas = 0
        Ti::PerfilAbertura.transaction do
          padrao = completar_padrao
          PERFIS.each do |nome, definicao|
            next if Ti::PerfilAbertura.exists?(nome: nome)

            perfil = Ti::PerfilAbertura.create!(nome: nome, descricao: definicao[:descricao])
            perfil.problemas << solicitacoes_dos_tipos(definicao[:tipos])
            pessoas += incluir(perfil, quem(definicao))
            criados << nome
          end
          @relatorio = Relatorio.new(criados: criados, pessoas: pessoas, inativados: inativar_antigos, apagados: apagar_o_de_teste, padrao: padrao.nome)
        end
        @relatorio
      end

      private

      # SERVIDORES ganha os problemas e senhas dos sistemas (não responsável), que são de todos.
      def completar_padrao
        padrao = self.class.perfil_padrao!
        faltam = solicitacoes_dos_tipos([ NAO_RESPONSAVEL ]).where.not(id: padrao.problemas.select(:id))
        padrao.problemas << faltam if faltam.any?
        padrao
      end

      def solicitacoes_dos_tipos(tipos) = Ti::Problema.joins(:categoria).where(ti_categorias: { nome: tipos }).where.not(legacy_id: nil)

      def quem(definicao)
        escolas = Legado::Api.ids_das_unidades_do_tipo("ESCOLA")
        gestao = Legado::Api.ids_dos_usuarios_com_papel("req_serv_ti_sis")
        requisitantes = @usuarios.where(id: Legado::Api.ids_dos_usuarios_com_papel("req_serv_ti") + gestao)
        do_lugar = definicao[:escola] ? requisitantes.where(unidade_id: escolas) : requisitantes.where.not(unidade_id: escolas).or(requisitantes.where(unidade_id: nil))
        definicao[:gestao] ? do_lugar.where(id: gestao) : do_lugar.where.not(id: gestao)
      end

      def incluir(perfil, usuarios)
        agora = Time.current
        linhas = usuarios.pluck(:id).map { |user_id| { perfil_abertura_id: perfil.id, user_id: user_id, created_at: agora, updated_at: agora } }
        Ti::PerfilUsuario.insert_all(linhas) if linhas.any?
        linhas.size
      end

      # Os perfis da primeira carga deixam de valer (ficam no banco, inativos, como histórico).
      def inativar_antigos
        Ti::PerfilAbertura.ativo.where(nome: ANTIGOS, padrao: false).map do |perfil|
          perfil.update!(status: "inativo")
          perfil.nome
        end
      end

      # O NORMAL foi criado pela tela num teste e está vazio: sai. Com alguém dentro, fica (alguém está usando).
      def apagar_o_de_teste
        perfil = Ti::PerfilAbertura.find_by(nome: DE_TESTE, padrao: false)
        return [] unless perfil && perfil.vinculos_de_usuario.none?

        perfil.destroy!
        [ DE_TESTE ]
      end
    end
  end
end
