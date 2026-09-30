require "test_helper"

class LedgerItemTest < ActiveSupport::TestCase
  setup do
    @user = users(:renato)
    @category = categories(:comunicacao_renato)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    @expense = @user.expenses.create!(name: "Internet", amount: BigDecimal("119.90"), category: @category)
  end

  # --- 4. criação de LedgerItem -----------------------------------------------

  test "cria item a partir do cadastro permanente, copiando os snapshots" do
    item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    assert item.save

    assert_equal "Internet", item.name_snapshot
    assert_equal "Comunicação", item.category_name_snapshot
    assert_equal BigDecimal("119.90"), item.amount
    assert_equal @expense.id, item.expense_id
  end

  test "nasce como não pago" do
    item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    item.save

    assert_not item.paid
    assert_includes LedgerItem.pending, item
    assert_not_includes LedgerItem.paid, item
  end

  test "exige os snapshots" do
    item = LedgerItem.new(ledger: @ledger, expense: @expense, amount: BigDecimal("1"))

    assert_not item.valid?
    assert_includes item.errors[:name_snapshot], "não pode ficar em branco"
    assert_includes item.errors[:category_name_snapshot], "não pode ficar em branco"
  end

  test "recusa valor negativo" do
    item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    item.amount = BigDecimal("-1")

    assert_not item.valid?
    assert_includes item.errors[:amount], "deve ser maior ou igual a 0"
  end

  # --- 5. snapshots não mudam quando Expense muda -----------------------------

  test "mudar o cadastro da despesa não altera a rubrica que já existe" do
    item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    item.save!

    @expense.update!(name: "Internet Fibra", amount: BigDecimal("129.90"))
    @expense.update!(category: @user.categories.create!(name: "Transporte"))

    item.reload

    assert_equal "Internet", item.name_snapshot
    assert_equal BigDecimal("119.90"), item.amount
    assert_equal "Comunicação", item.category_name_snapshot
  end

  test "os totais da rubrica também não mudam com a edição do cadastro" do
    LedgerItem.build_from(ledger: @ledger, expense: @expense).save!

    @expense.update!(amount: BigDecimal("999.99"))

    assert_equal BigDecimal("119.90"), @ledger.total_amount
  end

  # --- 11. estado de pagamento é do item, não da despesa ----------------------

  test "a mesma despesa pode estar paga em uma rubrica e pendente em outra" do
    fevereiro = @user.ledgers.create!(name: "Fevereiro 2026")

    janeiro_item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    janeiro_item.paid = true
    janeiro_item.save!

    fevereiro_item = LedgerItem.build_from(ledger: fevereiro, expense: @expense)
    fevereiro_item.save!

    assert janeiro_item.reload.paid
    assert_not fevereiro_item.reload.paid
    assert_equal @expense.id, janeiro_item.expense_id
    assert_equal @expense.id, fevereiro_item.expense_id
  end

  test "marcar como pago em uma rubrica não mexe na outra" do
    fevereiro = @user.ledgers.create!(name: "Fevereiro 2026")
    janeiro_item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    janeiro_item.save!
    fevereiro_item = LedgerItem.build_from(ledger: fevereiro, expense: @expense)
    fevereiro_item.save!

    fevereiro_item.update!(paid: true)

    assert_not janeiro_item.reload.paid
    assert_equal BigDecimal("0"), @ledger.paid_amount
  end
end
