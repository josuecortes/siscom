require "rails_helper"

# O Tailwind 4 trata `#` dentro de código Ruby no ERB como comentário e não gera
# classes com cor hexadecimal escritas ali (ex.: <%= ok ? "bg-[#ebf7ef]" : "" %>).
# Use variáveis do tema (bg-[var(--success-surface)]) ou deixe a classe fora do Ruby.
RSpec.describe "Classes do Tailwind nas views" do # rubocop:disable RSpec/DescribeClass
  it "não usa cor hexadecimal em classe dentro de código Ruby do ERB" do
    violacoes = Rails.root.glob("app/views/**/*.erb").flat_map do |arquivo|
      arquivo.read.scan(/<%=?(?!#).*?%>/m).grep(/\[#\h{3,8}\]/).map do |trecho|
        "#{arquivo.relative_path_from(Rails.root)}: #{trecho.squish.truncate(90)}"
      end
    end

    expect(violacoes).to be_empty, "Cores hexadecimais em Ruby de ERB:\n#{violacoes.join("\n")}"
  end
end
