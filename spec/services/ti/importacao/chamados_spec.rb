require "rails_helper"

# O cenário precisa do solicitante, do técnico e das referências antigas (unidade, problema) ao mesmo tempo.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Ti::Importacao::Chamados do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let(:unidade_antiga) { inserir_no_legado(:unidades, nome: "Núcleo de Informática", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "SEDE")) }
  let(:problema_antigo) { inserir_no_legado(:problema_tis, nome: "PRODOC - TROCAR SENHA", tipo_problema_ti_id: inserir_no_legado(:tipo_problema_tis, nome: "SISTEMAS WEB")) }
  let!(:solicitacao) do
    create(:ti_problema, nome: "Prodoc - Trocar senha", legacy_id: problema_antigo).tap do |problema|
      [ "Nome completo", "E-mail" ].each { |rotulo| problema.campos.create!(rotulo: rotulo, tipo: "texto") }
      problema.campos.create!(rotulo: "Observações", tipo: "texto_longo")
    end
  end
  let(:aberto_em) { Time.zone.local(2024, 3, 10, 9, 0) }

  before { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO", legacy_id: unidade_antiga) }

  def antigo(status, **outros)
    inserir_no_legado(:requisicao_tis, { status: status, user_id: maria.id, unidade_id: unidade_antiga, problema_ti_id: problema_antigo, observacoes: "Esqueci a senha." }.merge(outros)).tap do |id|
      ActiveRecord::Base.connection.execute("UPDATE requisicao_tis SET created_at = '#{aberto_em.utc.to_fs(:db)}', updated_at = '#{(aberto_em + 3.hours).utc.to_fs(:db)}' WHERE id = #{id}")
    end
  end

  def finalizado(**outros)
    antigo(5, **{ tecnico_id: joao.id, solucao: "Senha trocada.", avaliacao: 5, comentario: "Rápido!", nome: "Maria Oliveira", email: "maria@seed.ap.gov.br", cpf: "529.982.247-25",
                data_hora_em_atendimento: aberto_em + 1.hour, data_hora_concluida: aberto_em + 2.hours, data_hora_finalizada: aberto_em + 3.hours }.merge(outros))
  end

  it "o chamado finalizado chega com o mesmo número, a avaliação, os dados informados e o histórico nas datas antigas" do
    id = finalizado

    relatorio = described_class.call

    chamado = Ti::Chamado.find_by!(legacy_id: id)
    expect(relatorio).to have_attributes(antigos: 1, importados: 1, ja_existiam: 0, ignorados: [])
    expect(chamado).to have_attributes(id: id, codigo: format("TI-%06d", id), status: "finalizado", problema: solicitacao, solicitante: maria, solicitante_nome: "MARIA OLIVEIRA",
                                       responsavel: joao, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", aberto_em: aberto_em, concluido_em: aberto_em + 2.hours,
                                       finalizado_em: aberto_em + 3.hours, avaliacao: 5, avaliacao_resolvido: nil, avaliacao_comentario: "Rápido!")
    expect(chamado.valores.em_ordem.pluck(:rotulo, :valor_texto)).to contain_exactly([ "Observações", "Esqueci a senha." ], [ "Nome completo", "Maria Oliveira" ],
                                                                                    [ "E-mail", "maria@seed.ap.gov.br" ], [ "CPF", "529.982.247-25" ])
    expect(chamado.eventos.em_ordem.pluck(:tipo, :ator_nome, :ocorrido_em)).to eq(
      [ [ "aberto", "MARIA OLIVEIRA", aberto_em ], [ "assumido", "JOAO TECNICO", aberto_em + 1.hour ], [ "concluido", "JOAO TECNICO", aberto_em + 2.hours ],
        [ "finalizado", "MARIA OLIVEIRA", aberto_em + 3.hours ] ]
    )
    expect(chamado.eventos.em_ordem.pluck(:nota).values_at(2, 3)).to eq([ "Atendimento concluído: Senha trocada.", "Chamado finalizado pelo solicitante. Avaliação: Muito bom. Rápido!" ])
  end

  it "não afrouxa o banco: o dado que a solicitação não tem no formulário ganha um campo inativo, só do legado" do
    finalizado

    relatorio = described_class.call

    campo = solicitacao.campos.find_by!(rotulo: "CPF")
    expect(relatorio.campos_criados).to eq(1)
    expect(campo).to have_attributes(status: "inativo", ajuda: described_class::AJUDA_DO_CAMPO_ANTIGO)
    expect(Ti::ValorCampo.where(campo_problema_id: nil)).to be_empty
    expect(solicitacao.campos.ativo.pluck(:rotulo)).to eq([ "Nome completo", "E-mail", "Observações" ]) # quem abre chamado não vê o campo do legado
  end

  it "traduz cada situação antiga e não avisa ninguém" do
    ids = [ antigo(1), antigo(2, tecnico_id: joao.id, data_hora_em_atendimento: aberto_em + 1.hour),
            antigo(3, tecnico_id: joao.id, solucao: "Feito.", data_hora_em_atendimento: aberto_em + 1.hour, data_hora_concluida: aberto_em + 2.hours), antigo(4) ]

    expect { described_class.call }.not_to change(Core::Notificacao, :count)

    expect(Ti::Chamado.where(legacy_id: ids).order(:legacy_id).pluck(:status)).to eq(%w[aberto em_atendimento concluido cancelado])
    expect(Ti::Chamado.find_by!(legacy_id: ids.last).eventos.em_ordem.last).to have_attributes(tipo: "cancelado", ator_nome: "Siscom antigo")
  end

  it "as mensagens antigas viram a conversa do chamado, só para consulta e já lida" do
    id = finalizado
    [ [ maria, "Qual o prazo?" ], [ joao, "Hoje ainda." ], [ maria, " " ] ].each { |autor, texto| inserir_no_legado(:mensagens, status: "lida", texto: texto, user_id: autor.id, requisicao_ti_id: id) }

    relatorio = described_class.call

    conversa = Core::Api.conversa_de(Ti::Chamado.find_by!(legacy_id: id))
    expect(relatorio.mensagens).to eq(3)
    expect(conversa).to have_attributes(status: "somente_leitura", motivo_leitura: described_class::ENCERRADA)
    expect(conversa.mensagens.em_ordem.pluck(:autor_nome, :corpo)).to eq([ [ "MARIA OLIVEIRA", "Qual o prazo?" ], [ "JOAO TECNICO", "Hoje ainda." ] ])
    expect(conversa.participantes.map { |participante| [ participante.user, participante.pode_escrever, participante.nao_lidas ] }).to contain_exactly([ maria, false, 0 ], [ joao, false, 0 ])
  end

  it "pode rodar de novo sem duplicar, e o próximo chamado novo continua a numeração" do
    id = finalizado
    described_class.call

    relatorio = described_class.call
    novo = Ti::Chamado.create!(problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)

    expect(relatorio).to have_attributes(importados: 0, ja_existiam: 1)
    expect([ Ti::Chamado.where(legacy_id: id).count, Ti::ValorCampo.count, Ti::EventoChamado.count ]).to eq([ 1, 4, 4 ])
    expect(novo.id).to be > id
  end

  it "se o número antigo já está em uso por um chamado novo, o migrado recebe outro número" do
    id = finalizado
    ocupado = Ti::Chamado.create!(id: id, problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)

    described_class.call

    expect(Ti::Chamado.find_by!(legacy_id: id).id).not_to eq(ocupado.id)
  end

  it "chamado de solicitação que não está no catálogo novo é listado como ignorado, sem parar a migração" do
    fora = inserir_no_legado(:problema_tis, nome: "FORA DO CATALOGO", tipo_problema_ti_id: inserir_no_legado(:tipo_problema_tis, nome: "OUTRO"))
    ruim = antigo(1, problema_ti_id: fora)
    bom = antigo(1)

    relatorio = described_class.call

    expect(relatorio.ignorados).to eq([ "#{ruim}: solicitação não existe no sistema novo" ])
    expect(Ti::Chamado.pluck(:legacy_id)).to eq([ bom ])
  end

  describe "o chamado migrado continua andando no sistema novo" do
    before { create(:ti_grupo_tecnico, nome: "Suporte").tap { |grupo| solicitacao.grupos_tecnicos << grupo && grupo.vinculos_de_membro.create!(user: joao) } }

    it "o técnico conclui o que estava em atendimento e o solicitante finaliza com avaliação" do
      id = antigo(2, tecnico_id: joao.id, data_hora_em_atendimento: aberto_em + 1.hour)
      described_class.call
      chamado = Ti::Chamado.find_by!(legacy_id: id)

      expect(Ti::Chamados::Operar.call(chamado: chamado, acao: "concluir", ator: joao, nota: "Senha trocada agora.")).to be_sucesso
      expect(Ti::Chamados::Finalizar.call(chamado: chamado.reload, user: maria, resolvido: "sim", avaliacao: "4", comentario: nil)).to be_sucesso

      expect(chamado.reload).to have_attributes(status: "finalizado", avaliacao: 4, avaliacao_resolvido: true)
      expect(chamado.eventos.em_ordem.pluck(:tipo)).to eq(%w[aberto assumido concluido finalizado])
    end

    it "o solicitante finaliza o que tinha ficado só concluído no siscom antigo; o aberto pode ser assumido" do
      concluido = antigo(3, tecnico_id: joao.id, solucao: "Feito.", data_hora_em_atendimento: aberto_em + 1.hour, data_hora_concluida: aberto_em + 2.hours)
      aberto = antigo(1)
      described_class.call

      expect(Ti::Chamados::Finalizar.call(chamado: Ti::Chamado.find_by!(legacy_id: concluido), user: maria, resolvido: "sim", avaliacao: "5", comentario: nil)).to be_sucesso
      expect(Ti::Chamados::Operar.call(chamado: Ti::Chamado.find_by!(legacy_id: aberto), acao: "assumir", ator: joao)).to be_sucesso
      expect(Ti::Chamado.where(legacy_id: [ concluido, aberto ]).order(:legacy_id).pluck(:status)).to eq(%w[finalizado em_atendimento])
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
