module Rh
  module Importacao
    # Importa a estrutura do siscom antigo para o RH. Idempotente (usa `legacy_id`
    # e o vínculo pessoa ↔ conta): rodar de novo não duplica nada.
    #
    #   tipo_unidades → rh_tipos_unidade      unidades → rh_unidades
    #   funcoes → rh_funcoes                  cargos → rh_cargos
    #   users → rh_pessoas + rh_lotacoes (unidade_id + funcao_id) + pendências
    class DoLegado
      ORIGEM = "Importação do siscom antigo".freeze
      SIGLA_GENERICA = "ESCOLA".freeze

      Relatorio = Data.define(:tipos_unidade, :unidades, :funcoes, :cargos, :pessoas, :lotacoes, :pendencias) do
        def to_s
          "tipos de unidade: #{tipos_unidade}; unidades: #{unidades}; funções: #{funcoes}; cargos: #{cargos}; " \
            "pessoas: #{pessoas}; lotações: #{lotacoes}; pendências abertas: #{pendencias}"
        end
      end

      def self.call(...) = new(...).call

      def initialize(usuarios: ::User.where.not("email LIKE '%@siscom.dev'"))
        @usuarios = usuarios
      end

      def call
        ActiveRecord::Base.transaction do
          tipos = importar_referencia(Rh::TipoUnidade, Legado::Api.tipos_de_unidade)
          funcoes = importar_referencia(Rh::Funcao, Legado::Api.funcoes)
          importar_referencia(Rh::Cargo, Legado::Api.cargos)
          unidades = importar_unidades(tipos)
          importar_pessoas(unidades, funcoes)
        end

        Relatorio.new(
          tipos_unidade: Rh::TipoUnidade.count, unidades: Rh::Unidade.count, funcoes: Rh::Funcao.count, cargos: Rh::Cargo.count,
          pessoas: Rh::Pessoa.count, lotacoes: Rh::Lotacao.count, pendencias: Rh::PendenciaImportacao.abertas.group(:tipo).count
        )
      end

      private

      # Devolve { id_antigo => registro novo }. Nomes repetidos na tabela antiga
      # (diferindo só por maiúsculas/espaços) viram um registro só.
      def importar_referencia(modelo, antigos)
        antigos.each_with_object({}) do |antigo, mapa|
          nome = antigo[:nome].to_s.squish.upcase
          next if nome.blank?

          registro = modelo.find_by(legacy_id: antigo[:id]) || modelo.find_by(nome: nome) ||
                     modelo.create!(nome: nome, legacy_id: antigo[:id])
          mapa[antigo[:id]] = registro
        end
      end

      def importar_unidades(tipos)
        siglas_em_uso = Rh::Unidade.where.not(sigla: nil).pluck(:sigla).to_set

        Legado::Api.unidades.each_with_object({}) do |antiga, mapa|
          unidade = Rh::Unidade.find_or_initialize_by(legacy_id: antiga[:id])
          if unidade.new_record?
            sigla = antiga[:sigla].to_s.squish.upcase.presence
            # A sigla genérica "ESCOLA" e siglas repetidas não entram (a sigla é única no RH).
            sigla = nil if sigla == SIGLA_GENERICA || siglas_em_uso.include?(sigla)
            siglas_em_uso << sigla if sigla

            unidade.assign_attributes(nome: antiga[:nome].presence || "UNIDADE #{antiga[:id]}", sigla: sigla,
                                      tipo_unidade: tipos.fetch(antiga[:tipo_unidade_id]))
            unidade.save!(validate: false) # unidade antiga sem sigla e que não é escola também entra
          end
          mapa[antiga[:id]] = unidade
        end
      end

      def importar_pessoas(unidades, funcoes)
        cpfs_em_uso = Rh::Pessoa.where.not(cpf: nil).pluck(:cpf).to_set

        @usuarios.find_each do |user|
          pessoa = Rh::Pessoa.find_by(user_id: user.id) || criar_pessoa(user, cpfs_em_uso)
          lotar(pessoa, unidades[user.unidade_id], funcoes[user.funcao_id], user)
        end
      end

      def criar_pessoa(user, cpfs_em_uso)
        cpf = user.cpf.to_s.gsub(/\D/, "").presence
        problema = if cpf.nil? then "cpf_vazio"
        elsif !Rh::Pessoa.cpf_valido?(cpf) then "cpf_invalido"
        elsif cpfs_em_uso.include?(cpf) then "cpf_repetido"
        end
        cpfs_em_uso << cpf if cpf && problema.nil?

        celular = user.celular.to_s.gsub(/\D/, "")
        pessoa = Rh::Pessoa.new(user: user, nome: user.nome.presence || user.email, email: user.email,
                                cpf: (problema ? nil : cpf), data_nascimento: user.data_nascimento,
                                celular: (celular if celular.length.in?(10..11)))
        pessoa.save!(validate: false) # dados antigos incompletos entram e viram pendência
        pendencia(pessoa, problema, problema == "cpf_vazio" ? "Sem CPF no cadastro antigo." : "CPF no cadastro antigo: #{user.cpf}") if problema
        pendencia(pessoa, "nome_sem_sobrenome", "Nome no cadastro antigo: #{user.nome}") if pessoa.nome.split.size < 2
        pessoa
      end

      def lotar(pessoa, unidade, funcao, user)
        if unidade.nil? || funcao.nil?
          pendencia(pessoa, "sem_lotacao", "Usuário sem unidade ou função no cadastro antigo.")
          return
        end
        return if pessoa.lotacoes.exists?

        Rh::Lotacao.create!(pessoa: pessoa, unidade: unidade, funcao: funcao, data_inicio: user.created_at.to_date,
                            lotado_em: Time.current, lotado_por_nome: ORIGEM)
      end

      def pendencia(pessoa, tipo, descricao)
        Rh::PendenciaImportacao.find_or_create_by!(pessoa: pessoa, tipo: tipo) { |registro| registro.descricao = descricao }
      end
    end
  end
end
