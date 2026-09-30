# Adiciona uma despesa a uma rubrica.
#
# Duas operações em uma: garante o cadastro da despesa e cria o item dentro da
# rubrica, com os snapshots do momento.
#
# A despesa é **reaproveitada** quando já existe uma igual — mesmo nome, mesmo
# valor e mesma categoria. É o que torna "reutilizável" verdade: lançar
# "Internet 119,90" em Fevereiro usa a mesma despesa que já estava em Janeiro,
# em vez de criar uma segunda. Quando o valor muda, nasce uma despesa nova, que
# é exatamente a regra do produto.
module LedgerItems
  class Add
    def self.call(ledger:, name:, amount:, category:)
      new(ledger:, name:, amount:, category:).call
    end

    def initialize(ledger:, name:, amount:, category:)
      @ledger = ledger
      @name = name
      @amount = amount
      @category = category
    end

    def call
      # Atômico: não faz sentido um cadastro criado sem o item que o motivou.
      LedgerItem.transaction do
        LedgerItem.build_from(ledger:, expense: find_or_create_expense).save!
      end
    end

    private

    attr_reader :ledger, :name, :amount, :category

    def find_or_create_expense
      user = ledger.user
      user.expenses.find_by(name: name.strip.squish, amount: amount, category: category) ||
        user.expenses.create!(name: name, amount: amount, category: category)
    end
  end
end
