module Ti
  module Grupos
    # Deixa a pessoa exatamente nos grupos técnicos (ativos) informados: o mesmo vínculo de "Gerenciar membros",
    # visto pelo lado da pessoa (TI → Grupos técnicos → aba Técnicos). Só entra quem tem alguma permissão na TI;
    # sair, qualquer um sai. Audita uma vez e avisa a pessoa uma vez, com os grupos em que ela entrou.
    class DefinirDoUsuario
      def self.call(...) = new(...).call

      def initialize(user:, grupo_ids:, definido_por:)
        @user = user
        @grupo_ids = Array(grupo_ids).map(&:to_i).select(&:positive?).uniq
        @definido_por = definido_por
      end

      def call
        unless Core::Autorizacao.new(@definido_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @user)
        end

        ativos = Ti::GrupoTecnico.ativo.pluck(:id)
        atuais = Ti::MembroGrupo.where(user: @user, grupo_tecnico_id: ativos).pluck(:grupo_tecnico_id)
        desejados = ativos & @grupo_ids
        entram = desejados - atuais
        saem = atuais - desejados
        if entram.any? && !Ti::Grupos.elegiveis.exists?(id: @user.id)
          return Core::Resultado.falha("#{@user.nome} não tem permissão na TI. Conceda uma em TI → Administração → Permissões antes de pôr num grupo.", objeto: @user)
        end

        Ti::MembroGrupo.transaction do
          Ti::MembroGrupo.where(user: @user, grupo_tecnico_id: saem).destroy_all
          entram.each { |grupo_id| Ti::MembroGrupo.create!(user: @user, grupo_tecnico_id: grupo_id, concedido_por: @definido_por) }
        end
        avisar(entram, saem)
        Core::Resultado.sucesso(@user)
      end

      private

      def avisar(entram, saem)
        return if entram.empty? && saem.empty?

        Core::Api.auditar(evento: "ti.grupo_tecnico.membro_alterado", alvo: @user, ator: @definido_por, dados: { entrou_em: entram, saiu_de: saem })
        return if entram.empty?

        nomes = Ti::GrupoTecnico.where(id: entram).order(:nome).pluck(:nome)
        Core::Api.notificar(destinatarios: @user, evento: "ti.grupo_tecnico.entrou", titulo: (nomes.one? ? "Você entrou em um grupo técnico" : "Você entrou em grupos técnicos"),
                            mensagem: "Você agora faz parte #{nomes.one? ? 'do grupo técnico' : 'dos grupos técnicos'} #{nomes.to_sentence} da TI.")
      end
    end
  end
end
