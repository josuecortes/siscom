module Core
  module Importacao
    # Converte papéis antigos (Rolify) em concessões do modelo novo. Idempotente:
    # rodar de novo não duplica nada. Cada módulo chama com o seu mapa na fase
    # correspondente; o do Core está em MAPA_DO_CORE.
    #
    #   Core::Importacao::Papeis.call(Core::Importacao::Papeis::MAPA_DO_CORE)
    class Papeis
      MAPA_DO_CORE = {
        "master" => [ %w[core superadmin] ],
        "admin" => [ %w[core admin_usuarios] ]
      }.freeze

      Relatorio = Data.define(:concedidos, :ja_existiam, :ignorados) do
        def to_s = "#{concedidos} concedido(s), #{ja_existiam} já existia(m), #{ignorados.size} ignorado(s)"
      end

      def self.call(...) = new(...).call

      # mapa: { "papel_antigo" => [["modulo", "papel_novo"], ...] }
      def initialize(mapa)
        @mapa = mapa
      end

      def call
        concedidos = 0
        ja_existiam = 0
        ignorados = []

        @mapa.each do |papel_antigo, destinos|
          ::User.where(id: Legado::Api.ids_dos_usuarios_com_papel(papel_antigo)).find_each do |user|
            destinos.each do |modulo, papel|
              existia = Core::Concessao.ativo.exists?(user: user, modulo: modulo, papel: papel, escopo_id: nil)
              resultado = Core::Acessos::Conceder.call(user: user, modulo: modulo, papel: papel, pelo_sistema: true)

              if resultado.falha?
                ignorados << "#{user.email} (#{papel_antigo} → #{modulo}.#{papel}): #{resultado.mensagem_de_erro}"
              elsif existia
                ja_existiam += 1
              else
                concedidos += 1
              end
            end
          end
        end

        Relatorio.new(concedidos:, ja_existiam:, ignorados:)
      end
    end
  end
end
