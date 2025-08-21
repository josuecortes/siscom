# Seed para testar o sistema de equipamentos refatorado
puts "Criando equipamentos de teste..."

# Buscar usuário com role tec_serv_ti
user = User.joins(:roles).where(roles: { name: 'tec_serv_ti' }).first
if user.nil?
  puts "Nenhum usuário com role tec_serv_ti encontrado. Criando um..."
  user = User.first
  user.add_role(:tec_serv_ti) if user
end

# Buscar uma unidade
unidade = Unidade.first

if user && unidade
  # Criar equipamento individual
  equipamento_individual = Equipamento.create!(
    tipo: "individual",
    tipo_equipamento: "Monitor",
    descricao: "Monitor LED Samsung 24 polegadas, resolução Full HD",
    marca: "SAMSUNG",
    modelo: "24\" LED",
    numero_serial: "SN123456789",
    numero_patrimonio: "PAT001234",
    status: "ativo",
    unidade: unidade,
    user: user
  )
  puts "Equipamento individual criado: #{equipamento_individual.nome_completo}"

  # Criar equipamento individual 2
  equipamento_individual2 = Equipamento.create!(
    tipo: "individual",
    tipo_equipamento: "Impressora",
    descricao: "Impressora multifuncional HP LaserJet Pro",
    marca: "HP",
    modelo: "LaserJet Pro M404n",
    numero_serial: "SN987654321",
    numero_patrimonio: "PAT005678",
    status: "ativo",
    unidade: unidade,
    user: user
  )
  puts "Equipamento individual criado: #{equipamento_individual2.nome_completo}"

  # Criar kit de PCs
  kit_pcs = Equipamento.create!(
    tipo: "kit",
    descricao: "Kit completo de computadores para laboratório",
    identificacao_kit: "KIT001",
    status: "ativo",
    unidade: unidade,
    user: user
  )
  puts "Kit criado: #{kit_pcs.nome_completo}"

  # Criar equipamentos individuais do kit
  equipamentos_kit = [
    {
      tipo_equipamento: "Monitor",
      marca: "LG",
      modelo: "24\" LED",
      numero_serial: "SN111111111",
      numero_patrimonio: "PAT111111"
    },
    {
      tipo_equipamento: "Teclado",
      marca: "LOGITECH",
      modelo: "USB",
      numero_serial: "SN222222222",
      numero_patrimonio: "PAT222222"
    },
    {
      tipo_equipamento: "Mouse",
      marca: "LOGITECH",
      modelo: "Óptico USB",
      numero_serial: "SN333333333",
      numero_patrimonio: "PAT333333"
    },
    {
      tipo_equipamento: "Gabinete",
      marca: "INTEL",
      modelo: "i5, 8GB RAM",
      numero_serial: "SN444444444",
      numero_patrimonio: "PAT444444"
    }
  ]

  equipamentos_kit.each do |item|
    Equipamento.create!(
      tipo: "individual",
      tipo_equipamento: item[:tipo_equipamento],
      descricao: kit_pcs.descricao, # Mesma descrição do kit
      marca: item[:marca],
      modelo: item[:modelo],
      numero_serial: item[:numero_serial],
      numero_patrimonio: item[:numero_patrimonio],
      identificacao_kit: kit_pcs.identificacao_kit, # Link com o kit
      unidade: unidade, # Mesma unidade do kit
      user: user,
      status: "ativo"
    )
  end
  puts "Equipamentos do kit criados: #{equipamentos_kit.length} itens"

  puts "Seed de equipamentos concluído com sucesso!"
else
  puts "Erro: Usuário ou unidade não encontrados para criar equipamentos de teste."
end
