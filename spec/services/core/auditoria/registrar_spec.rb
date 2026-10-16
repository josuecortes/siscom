require "rails_helper"

RSpec.describe Core::Auditoria::Registrar do
  let(:ator) { create(:user, nome: "ADMIN DA SILVA") }
  let(:alvo) { create(:user, nome: "MARIA OLIVEIRA") }

  it "grava módulo, evento, ator, alvo e dados" do
    registro = described_class.call(evento: "core.usuario.criado", alvo: alvo, ator: ator, dados: { email: alvo.email })

    expect(registro).to have_attributes(modulo: "core", evento: "usuario.criado", ator: ator, ator_nome: "ADMIN DA SILVA",
                                        alvo_tipo: "User", alvo_id: alvo.id, alvo_descricao: "MARIA OLIVEIRA",
                                        dados: { "email" => alvo.email })
    expect(registro.rotulo).to eq("Usuário cadastrado")
  end

  it "usa o ator, o IP e o id da requisição do contexto" do
    Core::Contexto.set(ator: ator, ip: "10.0.0.7", request_id: "abc-123") do
      registro = described_class.call(evento: "core.usuario.ativado", alvo: alvo)

      expect(registro).to have_attributes(ator: ator, ip: "10.0.0.7", request_id: "abc-123")
    end
  end

  it "registra ação do sistema sem ator" do
    registro = described_class.call(evento: "core.usuario.criado", alvo: alvo, ator: nil)

    expect(registro.ator).to be_nil
    expect(registro.nome_do_ator).to eq("Sistema")
  end

  it "descarta senhas e segredos dos dados, em qualquer nível" do
    registro = described_class.call(evento: "core.x.y", ator: nil,
                                    dados: { email: "a@b.c", senha: "123", detalhe: { password: "x", token_api: "t", ok: 1 } })

    expect(registro.dados).to eq("email" => "a@b.c", "detalhe" => { "ok" => 1 })
  end

  it "não deixa alterar nem apagar um registro" do
    registro = described_class.call(evento: "core.usuario.criado", alvo: alvo, ator: ator)

    expect { registro.update!(evento: "outro") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { registro.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { Core::RegistroAuditoria.delete_all }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { Core::RegistroAuditoria.update_all(evento: "x") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "usa um rótulo legível para evento sem tradução" do
    expect(Core::RegistroAuditoria.rotulo_do_evento("ti", "chamado.aberto")).to eq("Chamado aberto")
  end
end
