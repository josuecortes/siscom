require "rails_helper"

# Gerado do catálogo real (config/modulos/*.yml): para cada papel de cada
# módulo, um usuário que só tem aquele papel pode exatamente o que o catálogo
# diz — e o catálogo não tem pontas soltas.
RSpec.describe "Matriz papel × permissão" do # rubocop:disable RSpec/DescribeClass
  Core::Catalogo.new(Rails.root.join("config/modulos")).modulos.each do |modulo|
    describe "módulo #{modulo.chave}" do
      automaticas = modulo.papeis_automaticos.flat_map { |papel| papel.permissoes.to_a }

      modulo.papeis.each_value do |papel|
        it "papel #{papel.chave} pode exatamente o que o catálogo declara" do
          user = create(:user)
          create(:core_concessao, user: user, modulo: modulo.chave, papel: papel.chave) unless papel.automatico?
          autorizacao = Core::Autorizacao.new(user)

          esperadas = (papel.permissoes.to_a + automaticas).uniq
          matriz = modulo.permissoes.keys.index_with { |local| autorizacao.pode?("#{modulo.chave}.#{local}") }

          expect(matriz).to eq(modulo.permissoes.keys.index_with { |local| esperadas.include?(local) })
        end
      end

      it "toda permissão pertence a pelo menos um papel" do
        usadas = modulo.papeis.values.flat_map { |papel| papel.permissoes.to_a }

        expect(modulo.permissoes.keys - usadas).to be_empty
      end

      it "todo item de menu aponta para uma rota existente" do
        rotas = modulo.menu.map(&:rota)

        expect(rotas.reject { |rota| Rails.application.routes.url_helpers.respond_to?(rota) }).to be_empty
      end
    end
  end

  it "papéis do Core só são concedidos por papéis do Core" do
    core = Core::Catalogo.modulo(:core)
    concediveis = core.concessao.values.flatten.uniq

    expect(core.papeis.keys - concediveis).to be_empty
  end
end
