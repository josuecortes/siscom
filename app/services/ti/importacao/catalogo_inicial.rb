module Ti
  module Importacao
    # Carga inicial do catálogo da TI a partir do siscom antigo, para o primeiro dia bater com
    # o que os usuários já conheciam. Idempotente (usa `legacy_id` e os nomes): rodar de novo
    # não duplica nada e não desfaz o que foi ajustado depois nas telas. NÃO migra chamados.
    #
    #   tipo_problema_tis → ti_categorias          problema_tis → ti_problemas (+ campos)
    #   regra escondida de abertura → perfis de abertura (Ti::Importacao::PerfisDeAbertura)
    #   tec_serv_ti → papel `tecnico` + grupo técnico SUPORTE TI (atende tudo)
    class CatalogoInicial
      # Tipos antigos em que o usuário podia ter vários chamados abertos ao mesmo tempo.
      TIPOS_COM_VARIOS_ABERTOS = [ "SISTEMAS WEB", "SISTEMAS WEB (NÃO RESPONSÁVEL)" ].freeze
      # Os perfis de abertura (quem abre o quê) são montados por PerfisDeAbertura.
      GRUPO = "SUPORTE TI".freeze
      CATEGORIA_GERAL = "OUTROS".freeze
      SOLICITACAO_GERAL = "SOLICITAÇÃO GERAL".freeze

      Relatorio = Data.define(:categorias, :solicitacoes, :campos, :perfis, :usuarios_em_perfis, :tecnicos) do
        def to_s
          "categorias: #{categorias}; solicitações: #{solicitacoes}; campos: #{campos}; perfis de abertura: #{perfis}; " \
            "usuários em perfis: #{usuarios_em_perfis}; técnicos no grupo #{GRUPO}: #{tecnicos}"
        end
      end

      def self.call(...) = new(...).call

      def initialize(usuarios: ::User.ativos.where.not("email LIKE '%@siscom.dev'"))
        @usuarios = usuarios
      end

      def call
        ActiveRecord::Base.transaction do
          Core::Api.publicar_fontes_padrao # os formulários usam as fontes do RH (cargos, funções, unidades)
          categorias = importar_categorias
          importar_solicitacoes(categorias)
          criar_solicitacao_geral
          criar_perfis(categorias)
          criar_grupo_tecnico
        end

        Relatorio.new(categorias: Ti::Categoria.count, solicitacoes: Ti::Problema.count, campos: Ti::CampoProblema.count,
                      perfis: Ti::PerfilAbertura.count, usuarios_em_perfis: Ti::PerfilUsuario.count,
                      tecnicos: Ti::GrupoTecnico.find_by(nome: GRUPO)&.membros&.count.to_i)
      end

      private

      # { id antigo => Ti::Categoria }
      def importar_categorias
        Legado::Api.tipos_de_problema_ti.to_h do |tipo|
          categoria = Ti::Categoria.find_by(legacy_id: tipo[:id]) ||
                      Ti::Categoria.create!(legacy_id: tipo[:id], nome: tipo[:nome], descricao: tipo[:descricao].to_s.truncate(300).presence)
          [ tipo[:id], categoria ]
        end
      end

      def importar_solicitacoes(categorias)
        Legado::Api.problemas_ti.each do |antigo|
          next if Ti::Problema.exists?(legacy_id: antigo[:id])

          categoria = categorias.fetch(antigo[:tipo_id])
          nome = nome_livre(categoria, antigo[:nome])
          solicitacao = Ti::Problema.create!(
            legacy_id: antigo[:id], categoria: categoria, nome: nome, status: (antigo[:ativo] ? "ativo" : "inativo"),
            descricao: antigo[:descricao].to_s.squish.truncate(500).presence || nome.capitalize,
            exige_triagem: false, permite_varios_abertos: TIPOS_COM_VARIOS_ABERTOS.include?(categoria.nome)
          )
          criar_campos(solicitacao, Formularios.para(antigo[:nome]))
        end
      end

      # O siscom antigo tinha nomes repetidos no mesmo tipo: o repetido entra com " (2)".
      def nome_livre(categoria, nome)
        nome = nome.to_s.squish.upcase
        usados = categoria.problemas.pluck(:nome)
        ([ nome ] + (2..9).map { |n| "#{nome} (#{n})" }).find { |candidato| usados.exclude?(candidato) }
      end

      def criar_campos(solicitacao, campos)
        campos.each do |campo|
          novo = solicitacao.campos.new(tipo: campo.fetch(:tipo, "texto"))
          novo.assign_attributes(campo.slice(:rotulo, :obrigatorio, :exemplo, :mascara, :ajuda, :opcoes, :fonte))
          novo.save!
        end
      end

      # Perfil padrão SERVIDORES (todo usuário) com uma solicitação descritiva: serve para qualquer pedido,
      # inclusive pedir inclusão em outros perfis de abertura.
      def criar_solicitacao_geral
        categoria = Ti::Categoria.find_or_create_by!(nome: CATEGORIA_GERAL) { |nova| nova.descricao = "Pedidos que não se encaixam nas outras categorias." }
        perfil = PerfisDeAbertura.perfil_padrao!
        return if categoria.problemas.exists?(nome: SOLICITACAO_GERAL)

        solicitacao = categoria.problemas.create!(
          nome: SOLICITACAO_GERAL, exige_triagem: true, permite_varios_abertos: true,
          descricao: "Descreva o que você precisa. Use também para pedir acesso a outros tipos de solicitação."
        )
        criar_campos(solicitacao, [ { rotulo: "Descreva o que você precisa", tipo: "texto_longo", obrigatorio: true },
                                    { rotulo: "Anexos", tipo: "arquivos", ajuda: "Opcional: fotos da tela, documentos." } ])
        solicitacao.perfis_abertura << perfil
      end

      # Quem abre o quê: os perfis de abertura (só preenchidos quando são criados).
      def criar_perfis(_categorias) = PerfisDeAbertura.call(usuarios: @usuarios)

      # No siscom antigo todo técnico via todas as requisições: um grupo só, que atende tudo.
      def criar_grupo_tecnico
        Core::Api.importar_papeis("tec_serv_ti" => [ %w[ti tecnico] ])
        return if Ti::GrupoTecnico.exists?(nome: GRUPO)

        grupo = Ti::GrupoTecnico.create!(nome: GRUPO, descricao: "Técnicos do siscom antigo. Atende todas as solicitações importadas.")
        grupo.problemas << Ti::Problema.all
        @usuarios.where(id: Legado::Api.ids_dos_usuarios_com_papel("tec_serv_ti")).find_each { |user| grupo.vinculos_de_membro.create!(user: user) }
      end
    end
  end
end
