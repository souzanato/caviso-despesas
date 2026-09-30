# Sugestão de nome para uma rubrica nova.
#
# Não é o sistema adivinhando o produto: é só continuidade. Quando a rubrica
# anterior segue o padrão "Mês Ano" — o caso mês-a-mês, que é o mais comum — o
# campo já vem com o mês seguinte, e criar vira um toque. Quando o nome é livre
# ("Viagem"), não há o que continuar e o campo vem vazio.
module LedgersHelper
  PATTERN = /\A(?<month>\p{L}+)\s+(?<year>\d{4})\z/

  def suggested_ledger_name(previous)
    return if previous.nil?

    match = previous.name.match(PATTERN)
    return if match.nil?

    month = I18n.t("date.month_names").index { |name| name.to_s.casecmp?(match[:month]) }
    return if month.nil?

    following = Date.new(match[:year].to_i, month, 1).next_month
    "#{I18n.l(following, format: '%B').capitalize} #{following.year}"
  end
end
