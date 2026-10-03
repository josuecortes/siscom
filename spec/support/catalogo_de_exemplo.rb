# Troca o catálogo real pelo de spec/fixtures/modulos (módulo "exemplo", com
# papel global, papel com escopo e papel automático).
RSpec.shared_context "com catálogo de exemplo" do
  let(:catalogo_de_exemplo) { Core::Catalogo.new(Rails.root.join("spec/fixtures/modulos")) }

  before { allow(Core::Catalogo).to receive(:atual).and_return(catalogo_de_exemplo) }
end
