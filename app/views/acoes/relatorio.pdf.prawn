prawn_document do
  # Cabeçalho
  text "Relatório da Ação: #{@acao.nome}", size: 20, style: :bold, align: :center
  move_down 20

  text "Motivação: #{@acao.motivacao}", size: 12
  text "Data de Início: #{@acao.inicio.strftime('%d/%m/%Y')}", size: 12

  if @acao.status != "Finalizada" && @acao.status != "Cancelada"
    text "Previsão de Término: #{@acao.termino.strftime('%d/%m/%Y')}", size: 12
  end

  move_down 20
  text "Etapas:", size: 16, style: :bold
  move_down 10

  @acao.etapas.each do |etapa|
    unless etapa.status == "Finalizada" || etapa.status == "Cancelada"
      text "Nome da Etapa: #{etapa.nome}", size: 12, style: :bold
      text "Descrição: #{etapa.descricao}", size: 12
      text "Data de Início: #{etapa.inicio.strftime('%d/%m/%Y')}", size: 12

      if etapa.termino
        text "Previsão de Término: #{etapa.termino.strftime('%d/%m/%Y')}", size: 12
      end

      move_down 10
      text "Participantes:", size: 12, style: :bold
      etapa.users.each do |user|
        text "- #{user.nome}", size: 12
      end

      move_down 20
    end
  end
end
