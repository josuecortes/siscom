class AcoesController < ApplicationController
  before_action :set_acao, only: %i[ show edit update destroy ]
  before_action :load_status, only: %i[ new edit create update ]

  # GET /acoes or /acoes.json
  def index
    @acoes = Acao.all
  end

  # GET /acoes/1 or /acoes/1.json
  def show
  end

  # GET /acoes/new
  def new
    @acao = Acao.new
  end

  # GET /acoes/1/edit
  def edit
  end

  # POST /acoes or /acoes.json
  def create
    @acao = Acao.new(acao_params)

    respond_to do |format|
      if @acao.save
        format.html { redirect_to acao_url(@acao), notice: "Acao was successfully created." }
        format.js {}
      else
        format.html { render :new, status: :unprocessable_entity }
        format.js { render :new }
      end
    end
  end

  # PATCH/PUT /acoes/1 or /acoes/1.json
  def update
    respond_to do |format|
      if @acao.update(acao_params)
        format.html { redirect_to acao_url(@acao), notice: "Acao was successfully updated." }
        format.js { render :update }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.html { render :edit, status: :unprocessable_entity }
        format.js { render :edit }
      end
    end
  end

  # DELETE /acoes/1 or /acoes/1.json
  def destroy
    @acao.destroy

    respond_to do |format|
      format.html { redirect_to acoes_url, notice: "Acao was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def relatorio
    @acao = Acao.includes(etapas: { etapa_users: :user }).find(params[:id])

    respond_to do |format|
      format.pdf do
        pdf = Prawn::Document.new(page_size: 'A4', margin: 50)

        # Cabeçalho
        pdf.text "#{@acao.nome}", size: 24, style: :bold, align: :center
        pdf.move_down 20

        pdf.text "<b>Local:</b>", inline_format: true, size: 14, style: :bold
        pdf.indent(20) do
          pdf.text @acao.local, size: 12, align: :justify, leading: 5
        end
        pdf.move_down 10

        if @acao.documento.present?
          pdf.text "<b>Documento:</b>", inline_format: true, size: 14, style: :bold
          pdf.indent(20) do
            pdf.text @acao.documento, size: 12, align: :justify, leading: 5
          end
          pdf.move_down 10
        end

        pdf.text "<b>Motivação:</b>", inline_format: true, size: 14, style: :bold
        pdf.indent(20) do
          pdf.text @acao.motivacao, size: 12, align: :justify, leading: 5
        end
        pdf.move_down 10

        pdf.text "<b>Complexidade:</b>", inline_format: true, size: 14, style: :bold
        pdf.indent(20) do
          pdf.text @acao.complexidade, size: 12, align: :justify, leading: 5
        end
        pdf.move_down 10

        pdf.text "<b>Período:</b>", inline_format: true, size: 14, style: :bold
        pdf.indent(20) do
          pdf.text "Início: #{@acao.inicio.strftime('%d/%m/%Y')}", size: 12
          if @acao.status != "Finalizada" && @acao.status != "Cancelada"
            pdf.text "Término: #{@acao.termino.strftime('%d/%m/%Y')}", size: 12
          end
        end
        pdf.move_down 10

        pdf.text "<b>Status:</b>", inline_format: true, size: 14, style: :bold
        pdf.indent(20) do
          pdf.text @acao.status, size: 12, align: :justify, leading: 5
        end

        pdf.move_down 20

        # Informações das Etapas
        pdf.text "Etapas:", size: 18, style: :bold, align: :left
        pdf.move_down 10

        @acao.etapas.each do |etapa|
          pdf.text "<b>Nome da Etapa:</b> #{etapa.nome}", inline_format: true, size: 14, style: :bold
          pdf.indent(20) do
            pdf.text "Descrição:", size: 12, style: :bold
            pdf.text etapa.descricao, size: 12, align: :justify, leading: 5

            pdf.move_down 5
            pdf.text "<b>Período:</b>", inline_format: true, size: 12, style: :bold
            pdf.text "Início: #{etapa.inicio.strftime('%d/%m/%Y')}", size: 12
            pdf.text "Término: #{etapa.termino.strftime('%d/%m/%Y')}" if etapa.termino

            pdf.move_down 5
            pdf.text "<b>Participantes:</b>", inline_format: true, size: 12, style: :bold
            etapa.etapa_users.each do |eu|
              pdf.text "- #{eu.user.nome}", size: 12, leading: 2
            end
          end

          pdf.move_down 15
        end

        # Rodapé
        pdf.number_pages "Página <page> de <total>", at: [pdf.bounds.right - 100, 0], align: :right, size: 10

        send_data pdf.render,
                  filename: "relatorio_acao_#{@acao.id}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  def relatorio_geral
    # @acoes = Acao.includes(etapas: { etapa_users: :user })
    @acoes = Acao.includes(etapas: { etapa_users: :user })
             .order(inicio: :asc, termino: :asc)
  
    respond_to do |format|
      format.pdf do
        pdf = Prawn::Document.new(page_size: 'A4', margin: 50, page_layout: :landscape)
  
        # Título Principal
        pdf.text "Relatório Geral de Ações", size: 28, style: :bold, align: :center, color: "0070C0"
        pdf.move_down 10
        pdf.text "Gerado em: #{Time.now.strftime('%d/%m/%Y %H:%M')}", size: 10, align: :right, color: "555555"
        pdf.move_down 20
  
        @acoes.each do |acao|
          # Cabeçalho da Ação
          pdf.text "<b>Ação:</b> #{acao.nome}", inline_format: true, size: 16, style: :bold, color: "333333"
          pdf.text "<b>Período:</b> #{acao.inicio.strftime('%d/%m/%Y')} à #{acao.termino.strftime('%d/%m/%Y')}", inline_format: true, size: 12
          pdf.text "<b>Local:</b> #{acao.local.present? ? acao.local : 'Não informado'}", inline_format: true, size: 12
          pdf.text "<b>Status:</b> #{acao.status}", inline_format: true, size: 12
          pdf.move_down 10
  
          # Tabela de Etapas
          etapa_data = [["Etapa", "Período", "Participantes", "Status"]]
          acao.etapas.order(inicio: :asc, termino: :asc).each do |etapa|
            participantes = etapa.etapa_users.map { |eu| eu.user.nome }.uniq.join("\n") # Quebra linha entre participantes
            periodo = etapa.termino ? "#{etapa.inicio.strftime('%d/%m/%Y')} à #{etapa.termino.strftime('%d/%m/%Y')}" : "Sem término"
            etapa_data << [etapa.nome, periodo, participantes, etapa.status]
          end
  
          # Renderização da Tabela
          pdf.table(etapa_data, header: true, row_colors: ["F8F8F8", "FFFFFF"], cell_style: { size: 10, inline_format: true, border_width: 1 }, width: pdf.bounds.width) do
            row(0).font_style = :bold
            row(0).background_color = "D9EDF7"
            column(0).width = 150 # Coluna "Etapa"
            column(2).width = 200 # Coluna "Participantes"
          end
  
          pdf.move_down 20
        end
  
        # Rodapé
        pdf.number_pages "Página <page> de <total>", at: [pdf.bounds.right - 100, 0], align: :right, size: 10
        
        send_data pdf.render,
                  filename: "relatorio_geral_acoes.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end
  


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_acao
      @acao = Acao.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def acao_params
      params.require(:acao).permit(
        :nome,
        :descricao,
        :inicio,
        :termino,
        :motivacao,
        :orcamento,
        :status,
        :mostrar_no_site,
        :user_id,
        :complexidade,
        :local,
        :documento
      )
    end

    def load_status
      @status = Acao.statuses.keys
    end
end
