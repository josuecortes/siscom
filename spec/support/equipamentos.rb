# Ajudantes dos specs de Equipamentos: pessoas lotadas em unidades (é a lotação do RH que diz de quem é o quê).
module AjudantesDeEquipamentos
  def lotar(user, unidade)
    pessoa = Rh::Pessoa.find_by(user: user) || create(:rh_pessoa, user: user, nome: user.nome, email: user.email)
    create(:rh_lotacao, pessoa: pessoa, unidade: unidade)
    user
  end

  def usuario_de_equipamentos(nome, unidade: nil, papel: nil)
    create(:user, nome: nome).tap do |user|
      create(:core_concessao, user: user, modulo: "equipamentos", papel: papel) if papel
      lotar(user, unidade) if unidade
    end
  end
end

RSpec.configure { |config| config.include AjudantesDeEquipamentos }
