# Usuários padrão de desenvolvimento/homologação: um por perfil (papel), com login e senha conhecidos,
# documentados em /Users/josue/projetos/seed/docs/refactor-remaster/USUARIOS-PADRAO.md.
# NUNCA roda em produção. Idempotente: pode rodar de novo a qualquer momento.
#
# Ao criar um módulo, papel ou permissão: acrescente o usuário aqui e atualize o documento.
namespace :remaster do
  namespace :dev do
    USUARIOS_PADRAO = [
      { nome: "PADRAO SUPERADMINISTRADOR", email: "superadmin@siscom.dev", papeis: [ %w[core superadmin] ] },
      { nome: "PADRAO ADMINISTRADOR DE USUARIOS", email: "admin.usuarios@siscom.dev", papeis: [ %w[core admin_usuarios] ] },
      { nome: "PADRAO AUDITOR", email: "auditor@siscom.dev", papeis: [ %w[core auditor] ] },
      { nome: "PADRAO RH ADMINISTRADOR", email: "rh.admin@siscom.dev", papeis: [ %w[rh admin] ] },
      { nome: "PADRAO RH OPERADOR", email: "rh.operador@siscom.dev", papeis: [ %w[rh operador] ] },
      { nome: "PADRAO RH LEITOR", email: "rh.leitor@siscom.dev", papeis: [ %w[rh leitor] ] },
      { nome: "PADRAO TI ADMINISTRADOR", email: "ti.admin@siscom.dev", papeis: [ %w[ti admin] ] },
      { nome: "PADRAO TI SUPERVISOR", email: "ti.supervisor@siscom.dev", papeis: [ %w[ti supervisor] ] },
      { nome: "PADRAO TI TRIADOR", email: "ti.triador@siscom.dev", papeis: [ %w[ti triagem] ] },
      { nome: "PADRAO TI TECNICO", email: "ti.tecnico@siscom.dev", papeis: [ %w[ti tecnico] ] },
      { nome: "PADRAO TRANSPORTE ADMINISTRADOR", email: "transporte.admin@siscom.dev", papeis: [ %w[transporte admin] ] },
      { nome: "PADRAO TRANSPORTE TECNICO", email: "transporte.tecnico@siscom.dev", papeis: [ %w[transporte tecnico] ] },
      { nome: "PADRAO TRANSPORTE MOTORISTA", email: "transporte.motorista@siscom.dev", papeis: [ %w[transporte motorista] ] },
      { nome: "PADRAO TRANSPORTE SOLICITANTE", email: "transporte.solicitante@siscom.dev", papeis: [ %w[transporte solicitante] ] },
      { nome: "PADRAO USUARIO COMUM", email: "usuario@siscom.dev", papeis: [] }
    ].freeze

    desc "Cria/atualiza os usuários padrão (um por perfil) para desenvolvimento e homologação. Não roda em produção."
    task usuarios_padrao: :environment do
      abort "Não roda em produção." if Rails.env.production? && ENV["PERMITIR_USUARIOS_PADRAO"] != "homologacao"

      senha = ENV.fetch("SENHA_USUARIOS_PADRAO", "Siscom@Dev2026")

      USUARIOS_PADRAO.each do |definicao|
        user = User.find_or_initialize_by(email: definicao[:email])
        user.assign_attributes(nome: definicao[:nome], status: true, deve_trocar_senha: false)
        unless user.persisted? && user.valid_password?(senha)
          user.senhas_anteriores.delete_all if user.persisted? # a senha padrão pode estar no histórico
          user.assign_attributes(password: senha, password_confirmation: senha)
        end
        user.save!
        user.unlock_access! if user.access_locked? || user.failed_attempts.positive?

        desejados = definicao[:papeis]
        Core::Concessao.ativo.where(user: user).reject { |c| desejados.include?([ c.modulo, c.papel ]) }.each do |concessao|
          concessao.update!(status: "inativo")
        end
        desejados.each do |modulo, papel|
          resultado = Core::Acessos::Conceder.call(user: user, modulo: modulo, papel: papel, pelo_sistema: true)
          abort "Falha em #{definicao[:email]}: #{resultado.mensagem_de_erro}" if resultado.falha?
        end

        papeis = desejados.map { |modulo, papel| "#{modulo}.#{papel}" }.join(", ").presence || "sem papéis"
        puts "#{definicao[:email].ljust(28)} #{papeis}"
      end

      # TI: triador e técnico só veem chamados dos grupos técnicos de que são membros.
      Ti::GrupoTecnico.ativo.find_each do |grupo|
        User.where(email: %w[ti.triador@siscom.dev ti.tecnico@siscom.dev]).find_each { |user| grupo.vinculos_de_membro.find_or_create_by!(user: user) }
      end
    end
  end
end
