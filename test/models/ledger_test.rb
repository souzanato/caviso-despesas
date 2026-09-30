require "test_helper"

class LedgerTest < ActiveSupport::TestCase
  setup do
    @user = users(:renato)
    @category = categories(:comunicacao_renato)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
  end

  def add_item(name:, amount:, paid: false)
    expense = @user.expenses.create!(name: name, amount: BigDecimal(amount), category: @category)
    LedgerItem.build_from(ledger: @ledger, expense: expense).tap do |item|
      item.paid = paid
      item.save!
    end
  end

  # --- 3. criação de rubrica --------------------------------------------------

  test "cria rubrica válida" do
    assert_predicate @ledger, :persisted?
    assert_equal @user.id, @ledger.user_id
  end

  test "aceita nomes que não são período" do
    # A rubrica é agrupador livre: nada no domínio exige mês ou ano.
    assert @user.ledgers.create!(name: "Viagem").persisted?
    assert @user.ledgers.create!(name: "Antes das férias").persisted?
  end

  test "exige nome" do
    ledger = @user.ledgers.build(name: "")

    assert_not ledger.valid?
    assert_includes ledger.errors[:name], "não pode ficar em branco"
  end

  test "recent_first ordena da mais nova para a mais antiga" do
    # @ledger veio do setup, então é a mais antiga das três.
    antiga = @user.ledgers.create!(name: "Antiga")
    nova = @user.ledgers.create!(name: "Nova")

    assert_equal [ nova.id, antiga.id, @ledger.id ], @user.ledgers.recent_first.map(&:id)
  end

  # --- 9, 10, 11. totais ------------------------------------------------------

  test "total_amount soma todos os itens" do
    add_item(name: "Escola", amount: "1850.00")
    add_item(name: "Internet", amount: "119.90")
    add_item(name: "Telefone", amount: "89.90")

    assert_equal BigDecimal("2059.80"), @ledger.total_amount
  end

  test "paid_amount soma só os itens pagos" do
    add_item(name: "Escola", amount: "1850.00", paid: true)
    add_item(name: "Internet", amount: "119.90", paid: false)

    assert_equal BigDecimal("1850.00"), @ledger.paid_amount
  end

  test "remaining_amount é o total menos o pago" do
    add_item(name: "Escola", amount: "1850.00", paid: true)
    add_item(name: "Internet", amount: "119.90", paid: false)
    add_item(name: "Telefone", amount: "89.90", paid: false)

    assert_equal BigDecimal("209.80"), @ledger.remaining_amount
  end

  test "rubrica vazia tem totais zerados, e não nil" do
    assert_equal BigDecimal("0"), @ledger.total_amount
    assert_equal BigDecimal("0"), @ledger.paid_amount
    assert_equal BigDecimal("0"), @ledger.remaining_amount
  end

  test "totais acompanham a marcação de pagamento" do
    item = add_item(name: "Internet", amount: "119.90")
    assert_equal BigDecimal("0"), @ledger.paid_amount
    assert_equal BigDecimal("119.90"), @ledger.remaining_amount

    item.update!(paid: true)

    assert_equal BigDecimal("119.90"), @ledger.paid_amount
    assert_equal BigDecimal("0"), @ledger.remaining_amount
  end

  test "apagar a rubrica leva os itens junto, sem tocar no cadastro de despesas" do
    add_item(name: "Internet", amount: "119.90")
    expense_count = Expense.count

    @ledger.destroy

    assert_equal 0, LedgerItem.where(ledger_id: @ledger.id).count
    assert_equal expense_count, Expense.count
  end
end
