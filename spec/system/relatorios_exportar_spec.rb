require "rails_helper"

# "Exportar Excel" dos relatórios leva o que está preenchido nos filtros, mesmo sem ter clicado em filtrar.
RSpec.describe "Exportar Excel com os filtros da tela", :js do
  def exportados(evento) = Core::RegistroAuditoria.where(evento: evento).order(:id).map(&:dados)

  # A planilha é um download: a página não muda, então espera o registro da exportação chegar.
  def esperar_exportacao(evento)
    50.times do
      break if exportados(evento).any?

      sleep 0.1
    end
  end

  it "TI: muda o período e exporta direto" do
    sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") }
    visit ti_estatisticas_path
    fill_in "Abertos de", with: "01/01/2024"
    fill_in "Até", with: "31/12/2024"

    click_on "Exportar Excel"

    esperar_exportacao("estatisticas.exportadas")
    expect(exportados("estatisticas.exportadas").last).to include("inicio" => "2024-01-01", "fim" => "2024-12-31")
    expect(page).to have_current_path(ti_estatisticas_path) # a tela continua onde estava
  end

  it "Transporte: muda o período e exporta direto" do
    sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "tecnico") }
    visit transporte_relatorios_path(tipo: "veiculos")
    fill_in "Início", with: "01/02/2026"
    fill_in "Fim", with: "28/02/2026"

    click_on "Exportar Excel"

    esperar_exportacao("relatorio.exportado")
    expect(exportados("relatorio.exportado").last).to include("tipo" => "veiculos", "inicio" => "2026-02-01", "fim" => "2026-02-28")
  end
end
