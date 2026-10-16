module Core
  module FontesReferencia
    # Publica (ou atualiza) uma fonte padrão, gerenciada pelo sistema, para cada
    # entidade publicável dos módulos. Idempotente; roda ao abrir a tela e pode
    # ser chamado por tasks.
    class Publicar
      def self.call = new.call

      def call
        Entidades.todas.map do |definicao|
          fonte = Core::FonteReferencia.find_or_initialize_by(chave: definicao.chave_padrao)
          fonte.assign_attributes(
            nome: definicao.nome, descricao: definicao.descricao, modulo: definicao.modulo, entidade: definicao.entidade,
            campo_rotulo: definicao.campo_rotulo, campo_valor: definicao.campo_valor, campo_subtitulo: definicao.campo_subtitulo,
            campos_busca: definicao.campos_busca, tipos_de_campo: Core::FonteReferencia::TIPOS_DE_CAMPO.keys,
            gerenciada_pelo_sistema: true
          )
          fonte.salvar_pelo_sistema! if fonte.new_record? || fonte.changed?
          fonte
        end
      end
    end
  end
end
