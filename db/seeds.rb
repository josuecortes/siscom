# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


Role.create([ {name: 'master'}, {name: 'admin'}, {name: 'user'}, {name: 'req_serv_ti'}, {name: 'req_serv_tp'}, {name: 'req_serv_md'}, {name: 'tec_serv_ti'}, {name: 'tec_serv_tp'}, {name: 'tec_serv_md'} ])

Funcao.create(nome: 'Master')

Departamento.create(nome: 'Núcleo de Informática', sigla: 'NUINFO')

master = User.new(nome: 'Master', email: 'master@seed.com', funcao_id: Funcao.first.id, departamento_id: Departamento.first.id)
master.add_role(:master)
master.add_role(:user)
master.add_role(:req_serv_ti)
master.save

administrador = User.new(nome: 'Administrador', email: 'administrador@seed.com', funcao_id: Funcao.first.id, departamento_id: Departamento.first.id)
administrador.add_role(:admin)
administrador.add_role(:user)
administrador.add_role(:req_serv_ti)
administrador.save
