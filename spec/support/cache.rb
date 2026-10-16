# Specs marcados com :com_cache usam um cache em memória de verdade
# (o ambiente de teste usa :null_store).
RSpec.configure do |config|
  config.around(:each, :com_cache) do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end
end

# expect { ... }.not_to exceed_query_limit(0)
RSpec::Matchers.define :exceed_query_limit do |limite|
  supports_block_expectations

  match do |bloco|
    @consultas = []
    contador = lambda do |*, payload|
      @consultas << payload[:sql] unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached]
    end
    ActiveSupport::Notifications.subscribed(contador, "sql.active_record", &bloco)
    @consultas.size > limite
  end

  failure_message_when_negated do
    "esperava no máximo #{limite} consultas, mas houve #{@consultas.size}:\n#{@consultas.join("\n")}"
  end
end
