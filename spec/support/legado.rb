# Ajudantes para montar dados do siscom antigo nos testes (os models do Legado
# são somente leitura, então os dados entram por SQL).
module AjudantesDoLegado
  def dar_papel_antigo(user, nome)
    conexao = ActiveRecord::Base.connection
    papel_id = conexao.select_value("SELECT id FROM roles WHERE name = #{conexao.quote(nome)} AND resource_type IS NULL") ||
               conexao.insert("INSERT INTO roles (name, created_at, updated_at) VALUES (#{conexao.quote(nome)}, now(), now())")
    conexao.execute("INSERT INTO users_roles (user_id, role_id) VALUES (#{user.id.to_i}, #{papel_id.to_i})")
  end
end

RSpec.configure { |config| config.include AjudantesDoLegado }
