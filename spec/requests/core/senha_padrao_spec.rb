require "rails_helper"

RSpec.describe "Administração: senha padrão das contas" do
  let(:superadmin) { create(:user, nome: "SUPER ADMIN").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  def senha_mostrada = response.body[%r{data-senha-temporaria>([^<]+)<}, 1]

  before { sign_in superadmin }

  it "sem senha padrão definida, cada conta recebe uma senha temporária diferente" do
    get core_configuracoes_path
    expect(response.body).to include("Senha padrão das contas", "Hoje não há senha padrão")

    senhas = Array.new(2) { patch(redefinir_senha_core_usuario_path(maria)) && senha_mostrada }
    expect(senhas.uniq.size).to eq(2)
  end

  it "a senha padrão é definida nas Configurações, fica cifrada no banco e não vai para a auditoria" do
    patch core_configuracoes_path, params: { configuracao: { senha_padrao: "curta" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Senha padrão deve ter de 8 a 128 caracteres")

    patch core_configuracoes_path, params: { configuracao: { senha_padrao: "Seed@Amapa2026" } }

    configuracao = Core::Configuracao.atual
    expect([ configuracao.senha_padrao, configuracao.senha_padrao_cifrada.include?("Seed@Amapa2026") ]).to eq([ "Seed@Amapa2026", false ])
    expect(Core::RegistroAuditoria.recentes.first.dados).to eq("mudancas" => { "acesso_inicial_das_contas" => "valor padrão definido ou trocado" })
    get core_configuracoes_path
    expect(Nokogiri::HTML(response.body).at_css("#configuracao_senha_padrao")["value"]).to eq("Seed@Amapa2026")
  end

  context "com a senha padrão definida" do
    before { Core::Configuracao.atual.update!(senha_padrao: "Seed@Amapa2026") }

    it "o cadastro de usuário usa a senha padrão e obriga a troca no primeiro acesso" do
      post core_usuarios_path, params: { user: { nome: "Ana Paula Lima", email: "ana@seed.ap.gov.br" } }

      ana = User.find_by!(email: "ana@seed.ap.gov.br")
      expect(senha_mostrada).to eq("Seed@Amapa2026")
      expect([ ana.valid_password?("Seed@Amapa2026"), ana.deve_trocar_senha? ]).to eq([ true, true ])
    end

    it "redefinir a senha aplica a padrão, quantas vezes for preciso, mesmo que ela já esteja no histórico" do
      3.times do
        patch redefinir_senha_core_usuario_path(maria)
        expect(senha_mostrada).to eq("Seed@Amapa2026")
      end

      expect([ maria.reload.valid_password?("Seed@Amapa2026"), maria.deve_trocar_senha? ]).to eq([ true, true ])
    end

    it "a pessoa não pode escolher a própria senha padrão como senha nova" do
      Core::Usuarios::RedefinirSenha.call(user: maria, pelo_sistema: true)

      recusada = Core::Usuarios::TrocarSenha.call(user: maria, senha_atual: "Seed@Amapa2026", nova_senha: "Seed@Amapa2026", confirmacao: "Seed@Amapa2026").mensagem_de_erro
      aceita = Core::Usuarios::TrocarSenha.call(user: maria.reload, senha_atual: "Seed@Amapa2026", nova_senha: "Minha#Senha2026", confirmacao: "Minha#Senha2026")

      expect(recusada).to eq("Senha não pode ser a senha padrão: escolha uma senha só sua")
      expect([ aceita.sucesso?, maria.reload.deve_trocar_senha? ]).to eq([ true, false ])
    end

    it "a pessoa cadastrada pelo RH e o motorista também recebem a senha padrão" do
      Rh::Tabelas.garantir_padroes
      pessoa = Rh::Pessoas::Salvar.call(pessoa: Rh::Pessoa.new, salvo_por: create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") },
                                        atributos: { nome: "Carla Mendes Souza", email: "carla@seed.ap.gov.br", celular: "96991234567", cpf: "111.444.777-35" }).objeto

      expect([ pessoa.senha_temporaria, pessoa.user.valid_password?("Seed@Amapa2026") ]).to eq([ "Seed@Amapa2026", true ])
    end

    it "apagando a senha padrão, volta a senha temporária aleatória" do
      patch core_configuracoes_path, params: { configuracao: { senha_padrao: "" } }
      patch redefinir_senha_core_usuario_path(maria)

      expect([ Core::Configuracao.atual.senha_padrao, senha_mostrada == "Seed@Amapa2026" ]).to eq([ nil, false ])
    end
  end
end
