module Equipamentos
  module Envios
    # Cria um envio de equipamentos de uma unidade para uma pessoa de outra unidade: movimentação definitiva,
    # empréstimo ou cautela (porta de movimentacao_equipamentos#create, mais o empréstimo).
    #
    # Regras: quem envia age na unidade de origem (gestor lotado nela, ou administrador); os equipamentos são
    # dessa unidade, ativos e livres; quem recebe está lotado na unidade de destino; origem e destino são
    # diferentes; empréstimo e cautela pedem a data prevista de devolução. Enviados, os equipamentos ficam
    # "em movimentação": não podem ser editados nem entrar em outro envio até serem recebidos ou cancelados.
    class Criar
      def self.call(...) = new(...).call

      def initialize(tipo:, origem_id:, destino_id:, responsavel_id:, item_ids:, criada_por:, descricao: nil, previsao_devolucao: nil)
        @tipo = Equipamentos::Movimentacao::TIPOS.key?(tipo.to_s) ? tipo.to_s : "movimentacao"
        @origem = Rh::Api.unidade(origem_id)
        @destino = Rh::Api.unidade(destino_id)
        @responsavel = ::User.ativos.find_by(id: responsavel_id)
        @item_ids = Array(item_ids).map(&:to_i).select(&:positive?).uniq
        @criada_por = criada_por
        @descricao = descricao.to_s.squish.presence
        @previsao = DataBr.interpretar(previsao_devolucao)
      end

      def call
        @envio = montar
        erro = recusa
        return Core::Resultado.falha(erro, objeto: @envio) if erro

        Equipamentos::Movimentacao.transaction do
          @envio.save!
          itens.each do |item|
            item.lock!
            raise ActiveRecord::RecordNotUnique, "equipamento em outro envio" unless item.reload.livre?

            @envio.itens.create!(item: item, status: "pendente")
            item.update!(situacao: "em_movimentacao")
            item.registrar_evento((emprestimo? ? "emprestimo_criado" : "movimentacao_criada"), @criada_por,
                                  "#{@envio.nome_do_tipo} #{@envio.codigo}: de #{@origem.sigla_e_nome} para #{@destino.sigla_e_nome}, aos cuidados de #{@responsavel.nome}." \
                                  "#{" Devolução prevista para #{I18n.l(@previsao)}." if emprestimo?}")
          end
          Core::Api.auditar(evento: "equipamentos.envio.criado", alvo: @envio, ator: @criada_por,
                            dados: { codigo: @envio.codigo, tipo: @tipo, origem: @origem.sigla_e_nome, destino: @destino.sigla_e_nome, para: @responsavel.nome, equipamentos: itens.size,
                                     em_nome_da_unidade: (true unless Acesso.ids_das_unidades_de(@criada_por).include?(@origem.id)) }.compact)
        end
        avisar
        Core::Resultado.sucesso(@envio)
      rescue ActiveRecord::RecordNotUnique
        Core::Resultado.falha("Um dos equipamentos acabou de entrar em outro envio. Confira a lista e tente de novo.", objeto: @envio)
      end

      private

      def emprestimo? = Equipamentos::Movimentacao::DE_EMPRESTIMO.include?(@tipo)
      def itens = @itens ||= Equipamentos::Item.where(id: @item_ids).order(:id).to_a

      def montar
        Equipamentos::Movimentacao.new(tipo: @tipo, origem_rh_unidade_id: @origem&.id, origem_nome: @origem&.sigla_e_nome, destino_rh_unidade_id: @destino&.id,
                                       destino_nome: @destino&.sigla_e_nome, responsavel: @responsavel, responsavel_nome: @responsavel&.nome, criada_por: @criada_por,
                                       criada_por_nome: @criada_por.nome, descricao: @descricao, previsao_devolucao: (@previsao if emprestimo?))
      end

      def recusa
        permissao = emprestimo? ? Acesso::EMPRESTAR : Acesso::MOVIMENTAR
        return "Você não pode #{emprestimo? ? 'emprestar' : 'movimentar'} equipamentos." unless Acesso.pode?(@criada_por, permissao)
        return "Escolha a unidade de origem." unless @origem
        return "Você só pode enviar equipamentos das unidades em que está lotado." unless Acesso.age_na_unidade?(@criada_por, @origem.id)
        return "Escolha a unidade de destino." unless @destino
        return "A unidade de destino deve ser diferente da de origem." if @destino.id == @origem.id
        return "Escolha quem vai receber." unless @responsavel
        return "#{@responsavel.nome} não está lotado(a) em #{@destino.sigla_e_nome}." unless Rh::Api.ids_dos_usuarios_da_unidade(@destino.id).include?(@responsavel.id)
        return "Escolha pelo menos um equipamento." if @item_ids.empty?
        return "Data prevista de devolução deve ser preenchida (dd/mm/aaaa)." if emprestimo? && @previsao.nil?
        return "A data prevista de devolução não pode estar no passado." if emprestimo? && @previsao < Date.current

        recusa_dos_itens
      end

      def recusa_dos_itens
        return "Um dos equipamentos escolhidos não existe mais." unless itens.size == @item_ids.size

        de_fora = itens.reject { |item| item.rh_unidade_id == @origem.id }
        return "#{de_fora.first.nome_completo} não é da unidade #{@origem.sigla_e_nome}." if de_fora.any?

        presos = itens.reject(&:livre?)
        return nil if presos.empty?

        item = presos.first
        "#{item.nome_completo} está #{(item.ativo? ? item.nome_da_situacao : item.nome_do_status).downcase} e não pode ser enviado."
      end

      def avisar
        titulo = emprestimo? ? "#{@envio.nome_do_tipo} de equipamento para você aceitar" : "Equipamentos para você receber"
        Avisos.notificar(@responsavel, @envio, @criada_por, "criado", titulo,
                         "#{@envio.codigo}: #{itens.size} equipamento(s) de #{@origem.sigla_e_nome}, enviados por #{@criada_por.nome}.")
        Avisos.atualizar_telas(@envio)
      end
    end
  end
end
