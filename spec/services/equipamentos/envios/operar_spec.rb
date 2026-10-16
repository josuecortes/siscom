require "rails_helper"

# Movimentação, empréstimo/cautela e devolução de equipamentos, de ponta a ponta.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Equipamentos::Envios::Operar do
  let(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let(:asjur) { create(:rh_unidade, nome: "Assessoria Jurídica", sigla: "ASJUR") }
  let(:gestor) { usuario_de_equipamentos("GESTOR DO NUINFO", unidade: nuinfo, papel: "gestor") }
  let(:outro_gestor) { usuario_de_equipamentos("GESTORA DA ASJUR", unidade: asjur, papel: "gestor") }
  let(:maria) { usuario_de_equipamentos("MARIA OLIVEIRA", unidade: asjur) }
  let(:admin) { usuario_de_equipamentos("ADMIN DE EQUIPAMENTOS", papel: "admin") }
  let(:monitor) { create(:equipamentos_item, unidade: nuinfo, numero_patrimonio: "PAT001") }
  let(:teclado) { create(:equipamentos_item, unidade: nuinfo, tipo_equipamento: "Teclado", numero_patrimonio: "PAT002") }

  def enviar(tipo: "movimentacao", itens: [ monitor, teclado ], por: gestor, para: maria, destino: asjur, **outros)
    Equipamentos::Envios::Criar.call(tipo: tipo, origem_id: nuinfo.id, destino_id: destino.id, responsavel_id: para.id, item_ids: itens.map(&:id), criada_por: por, **outros)
  end

  def operar(envio, acao, ator, **outros) = described_class.call(envio: envio.reload, acao: acao, ator: ator, **outros)

  describe "movimentação" do
    it "enviados, os equipamentos ficam em movimentação: não entram em outro envio nem são editados; quem recebe é avisado" do
      envio = enviar.objeto

      expect(envio).to have_attributes(codigo: "MV-#{format('%06d', envio.id)}", status: "em_andamento", origem_nome: "NUINFO - NÚCLEO DE INFORMÁTICA", responsavel: maria)
      expect([ monitor.reload.situacao, teclado.reload.situacao ]).to eq(%w[em_movimentacao em_movimentacao])
      expect(enviar(itens: [ monitor ]).mensagem_de_erro).to include("está em movimentação e não pode ser enviado")
      expect(Equipamentos::Itens::Salvar.call(item: monitor, atributos: { marca: "LG" }, salvo_por: gestor).mensagem_de_erro).to include("em movimentação e não pode ser alterado")
      expect(maria.notificacoes.sole.titulo).to eq("Equipamentos para você receber")
    end

    it "só envia quem age na unidade de origem, para alguém lotado no destino, com equipamentos ativos da origem" do
      da_asjur = create(:equipamentos_item, unidade: asjur)
      inativo = create(:equipamentos_item, unidade: nuinfo, status: "inativo")

      expect([ enviar(por: outro_gestor), enviar(por: maria), enviar(para: gestor), enviar(destino: nuinfo, para: gestor), enviar(itens: [ da_asjur ]), enviar(itens: [ inativo ]),
               enviar(itens: []) ].map(&:mensagem_de_erro))
        .to match([ /só pode enviar equipamentos das unidades em que está lotado/, /não pode movimentar/, /GESTOR DO NUINFO não está lotado\(a\) em ASJUR/, /deve ser diferente da de origem/,
                    /não é da unidade NUINFO/, /está inativo e não pode ser enviado/, /Escolha pelo menos um equipamento/ ])
      expect(enviar(por: admin)).to be_sucesso # o administrador age em nome de qualquer unidade
    end

    it "recebido item a item, o equipamento passa a ser da nova unidade; com tudo recebido o envio conclui" do
      envio = enviar.objeto

      expect(operar(envio, "receber_item", gestor, item_id: monitor.id)).to be_falha # só quem recebe
      operar(envio, "receber_item", maria, item_id: monitor.id)
      expect(monitor.reload).to have_attributes(rh_unidade_id: asjur.id, unidade_nome: "ASJUR - ASSESSORIA JURÍDICA", situacao: "disponivel")
      expect(envio.reload).to be_em_andamento

      operar(envio, "receber_item", maria, item_id: teclado.id)
      expect(envio.reload).to have_attributes(status: "concluida", encerrada_em: be_present)
      expect([ monitor.eventos.em_ordem.pluck(:tipo), gestor.notificacoes.count ]).to eq([ %w[movimentacao_criada movimentacao_recebida], 2 ])
    end

    it "quem criou cancela o envio de um equipamento ainda não recebido; o recebido não volta" do
      envio = enviar.objeto
      operar(envio, "receber_item", maria, item_id: monitor.id)

      expect(operar(envio, "cancelar_item", maria, item_id: teclado.id)).to be_falha
      expect(operar(envio, "cancelar_item", gestor, item_id: monitor.id).mensagem_de_erro).to include("já foi recebido ou cancelado")
      operar(envio, "cancelar_item", gestor, item_id: teclado.id)

      expect(teclado.reload).to have_attributes(rh_unidade_id: nuinfo.id, situacao: "disponivel")
      expect(envio.reload.status).to eq("concluida")
    end

    it "cancelado tudo, o envio fica cancelado" do
      envio = enviar(itens: [ monitor ]).objeto

      operar(envio, "cancelar_item", gestor, item_id: monitor.id)

      expect(envio.reload.status).to eq("cancelada")
    end

    it "o administrador dá o recebido em nome de quem recebe, e isso fica registrado" do
      envio = enviar(itens: [ monitor ]).objeto

      operar(envio, "receber_item", admin, item_id: monitor.id)

      expect(monitor.eventos.em_ordem.last.nota).to include("recebido por MARIA OLIVEIRA", "feito por ADMIN DE EQUIPAMENTOS, administrador, em nome de MARIA OLIVEIRA")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "envio.item_recebido", ator: admin, dados: include("pelo_administrador" => true))
    end
  end

  describe "empréstimo e cautela" do
    let(:previsao) { 10.days.from_now.to_date }

    def emprestar(**outros) = enviar(tipo: "cautela", itens: [ monitor ], previsao_devolucao: I18n.l(previsao), **outros)

    it "pede a data prevista de devolução, que não pode estar no passado" do
      expect([ enviar(tipo: "emprestimo").mensagem_de_erro, enviar(tipo: "emprestimo", previsao_devolucao: I18n.l(Date.yesterday)).mensagem_de_erro ])
        .to match([ /Data prevista de devolução deve ser preenchida/, /não pode estar no passado/ ])
    end

    it "aceito o termo, o equipamento continua da origem mas fica com a outra unidade; o termo aceito fica guardado" do
      envio = emprestar.objeto
      expect(operar(envio, "receber_item", maria, item_id: monitor.id).mensagem_de_erro).to include("aceite do termo")

      operar(envio, "aceitar", maria)

      expect(monitor.reload).to have_attributes(rh_unidade_id: nuinfo.id, situacao: "emprestado", posse_rh_unidade_id: asjur.id, posse_unidade_nome: "ASJUR - ASSESSORIA JURÍDICA")
      expect(envio.reload).to have_attributes(codigo: start_with("EM-"), status: "em_andamento", aceita_em: be_present)
      expect(envio.termo).to include("Eu, MARIA OLIVEIRA, lotado(a) em ASJUR - ASSESSORIA JURÍDICA", "recebi de GESTOR DO NUINFO", "a título de cautela", "patrimônio PAT001",
                                     "até #{I18n.l(previsao)}")
      expect([ Equipamentos::Acesso.itens_visiveis(gestor), Equipamentos::Acesso.itens_visiveis(outro_gestor) ].map { |itens| itens.exists?(id: monitor.id) }).to eq([ true, true ])
    end

    it "emprestado, ninguém movimenta nem edita: quem recebeu só devolve" do
      envio = emprestar.objeto
      operar(envio, "aceitar", maria)

      expect(enviar(itens: [ monitor ]).mensagem_de_erro).to include("está emprestado e não pode ser enviado")
      expect(Equipamentos::Envios::Criar.call(tipo: "movimentacao", origem_id: asjur.id, destino_id: nuinfo.id, responsavel_id: gestor.id, item_ids: [ monitor.id ], criada_por: outro_gestor)
                                        .mensagem_de_erro).to include("não é da unidade ASJUR")
      expect(Equipamentos::Itens::Salvar.call(item: monitor.reload, atributos: { marca: "LG" }, salvo_por: gestor)).to be_falha
      expect(operar(envio, "cancelar_item", gestor, item_id: monitor.id)).to be_falha # depois do aceite não se cancela: devolve-se
    end

    it "antes do aceite, quem criou pode cancelar" do
      envio = emprestar.objeto

      operar(envio, "cancelar_item", gestor, item_id: monitor.id)

      expect([ envio.reload.status, monitor.reload.situacao ]).to eq(%w[cancelada disponivel])
    end

    it "a devolução é iniciada por quem está com o equipamento, para alguém da unidade de origem, e conclui quando essa pessoa recebe" do
      envio = emprestar.objeto
      operar(envio, "aceitar", maria)

      recusas = [ operar(envio, "devolver", maria, para_id: outro_gestor.id), operar(envio, "devolver", gestor, para_id: gestor.id) ].map(&:mensagem_de_erro)
      operar(envio, "devolver", maria, para_id: gestor.id)
      recusas << operar(envio, "receber_devolucao", maria).mensagem_de_erro
      expect(recusas).to match([ /não está lotado\(a\) em NUINFO/, /Só MARIA OLIVEIRA pode devolver/, /Não há devolução deste envio para você receber/ ])
      # Ainda com ela até receberem.
      expect([ envio.itens.sole.status, envio.itens.sole.devolver_para, monitor.reload.situacao ]).to eq([ "devolucao_pendente", gestor, "emprestado" ])

      operar(envio, "receber_devolucao", gestor, observacao: "Voltou com o cabo trocado.")

      expect(monitor.reload).to have_attributes(situacao: "disponivel", posse_rh_unidade_id: nil, rh_unidade_id: nuinfo.id)
      expect(envio.reload.itens.sole).to have_attributes(status: "devolvido", devolucao_recebida_por: gestor, observacao_da_devolucao: "Voltou com o cabo trocado.")
      expect([ envio.status, monitor.eventos.em_ordem.pluck(:tipo) ]).to eq([ "concluida", %w[emprestimo_criado emprestimo_aceito devolucao_pedida devolucao_recebida] ])
    end

    it "devolução parada: quem devolve troca a pessoa indicada" do
      pedro = usuario_de_equipamentos("PEDRO SANTOS", unidade: nuinfo)
      envio = emprestar.objeto
      operar(envio, "aceitar", maria)
      operar(envio, "devolver", maria, para_id: gestor.id)

      operar(envio, "devolver", maria, para_id: pedro.id)

      expect(envio.itens.sole).to have_attributes(status: "devolucao_pendente", devolver_para: pedro)
      expect(operar(envio, "receber_devolucao", gestor)).to be_falha
      expect(operar(envio, "receber_devolucao", pedro)).to be_sucesso
    end

    it "conta os dias emprestado e os dias de atraso" do
      envio = emprestar.objeto
      operar(envio, "aceitar", maria)

      travel_to(previsao + 3.days) { expect([ envio.reload.dias_de_atraso, envio.dias_emprestado ]).to eq([ 3, 13 ]) }
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
