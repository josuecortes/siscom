ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "funcao", "funcoes"
  inflect.irregular "unidade", "unidades"
  inflect.irregular "tipo_unidade", "tipo_unidades"
  inflect.irregular "cargo", "cargos"
  inflect.irregular "motorista", "motoristas"
  inflect.irregular "veiculo", "veiculos"
  inflect.irregular "requisicao_transporte", "requisicao_transportes"
  inflect.irregular "passageiro", "passageiros"
  inflect.irregular "destino", "destinos"
  inflect.irregular "servico_transporte", "servico_transportes"
  inflect.irregular "requisicao_ti", "requisicao_tis"
  inflect.irregular "problema_ti", "problema_tis"
  inflect.irregular "tipo_problema_ti", "tipo_problema_tis"
  inflect.irregular "mensagem", "mensagens"
  inflect.irregular "incidente", "incidentes"
  inflect.irregular "transportador", "transportadores"
  inflect.irregular "condutor", "condutores"
  inflect.irregular "servico", "servicos"

  inflect.irregular "acao", "acoes"
  inflect.irregular "acao_user", "acao_users"
  inflect.irregular "acao_unidade", "acao_unidades"
end

# Plurais em português usados nos nomes do remaster (rotas, tabelas, classes):
# notificacao/notificacoes, concessao/concessoes, configuracao/configuracoes...
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(/([cs])ao\z/i, '\1oes')
  inflect.singular(/([cs])oes\z/i, '\1ao')
  inflect.irregular "fonte_referencia", "fontes_referencia"
  inflect.irregular "tipo_unidade", "tipos_unidade"
  inflect.irregular "tipo_local", "tipos_local"
  inflect.irregular "tipo_vinculo", "tipos_vinculo"
  inflect.irregular "lotacao", "lotacoes"
  inflect.irregular "pendencia", "pendencias"
  inflect.irregular "perfil_abertura", "perfis_abertura"
  inflect.irregular "grupo_tecnico", "grupos_tecnicos"
end
