require "rails_helper"

RSpec.describe Equipamentos::AlertasJob do
  let(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let(:asjur) { create(:rh_unidade, nome: "Assessoria Jurídica", sigla: "ASJUR") }
  let(:gestor) { usuario_de_equipamentos("GESTOR DO NUINFO", unidade: nuinfo, papel: "gestor") }
  let(:outro_gestor) { usuario_de_equipamentos("OUTRA GESTORA DO NUINFO", unidade: nuinfo, papel: "gestor") }
  let(:maria) { usuario_de_equipamentos("MARIA OLIVEIRA", unidade: asjur) }

  def emprestar
    item = create(:equipamentos_item, unidade: nuinfo)
    Equipamentos::Envios::Criar.call(tipo: "emprestimo", origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: maria.id, item_ids: [ item.id ], criada_por: gestor,
                                     previsao_devolucao: 5.days.from_now.to_date).objeto
  end

  it "avisa uma vez quem está com o equipamento e os gestores da origem quando a devolução vence" do
    outro_gestor
    atrasado = emprestar.tap { |envio| Equipamentos::Envios::Operar.call(envio: envio, acao: "aceitar", ator: maria) }
    no_prazo = emprestar.tap { |envio| Equipamentos::Envios::Operar.call(envio: envio, acao: "aceitar", ator: maria) }
    sem_aceite = emprestar
    [ atrasado, sem_aceite ].each { |envio| envio.update_columns(previsao_devolucao: 2.days.ago.to_date) }
    Core::Notificacao.delete_all

    2.times { described_class.perform_now }

    expect(Core::Notificacao.where(modulo: "equipamentos", evento: "envio.atrasado").pluck(:user_id, :titulo))
      .to contain_exactly([ maria.id, "Devolução de equipamento atrasada" ], [ gestor.id, "Empréstimo com a devolução atrasada" ], [ outro_gestor.id, "Empréstimo com a devolução atrasada" ])
    expect([ atrasado, no_prazo, sem_aceite ].map { |envio| envio.reload.atraso_avisado_em.present? }).to eq([ true, false, false ])
  end
end
