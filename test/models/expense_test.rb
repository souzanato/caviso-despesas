require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @user = users(:renato)
    @category = categories(:comunicacao_renato)
  end

  def build_expense(**attrs)
    @user.expenses.build({ name: "Internet", amount: BigDecimal("119.90"), category: @category }.merge(attrs))
  end

  # --- 2. criação de despesa --------------------------------------------------

  test "cria despesa válida" do
    expense = build_expense
    assert expense.save

    assert_predicate expense, :persisted?
    assert_equal @user.id, expense.user_id
    assert_equal @category.id, expense.category_id
  end

  test "o valor é BigDecimal, nunca float" do
    expense = build_expense
    expense.save

    assert_instance_of BigDecimal, expense.reload.amount
    assert_equal BigDecimal("119.90"), expense.amount
  end

  test "exige nome" do
    expense = build_expense(name: "")

    assert_not expense.valid?
    assert_includes expense.errors[:name], "não pode ficar em branco"
  end

  test "exige valor" do
    expense = build_expense(amount: nil)

    assert_not expense.valid?
    assert_includes expense.errors[:amount], "não pode ficar em branco"
  end

  test "exige categoria" do
    expense = build_expense(category: nil)

    assert_not expense.valid?
    assert_includes expense.errors[:category], "é obrigatório(a)"
  end

  test "recusa valor negativo" do
    expense = build_expense(amount: BigDecimal("-0.01"))

    assert_not expense.valid?
    assert_includes expense.errors[:amount], "deve ser maior ou igual a 0"
  end

  test "aceita valor zero" do
    assert build_expense(amount: BigDecimal("0")).valid?
  end

  test "o banco também recusa valor negativo" do
    assert_raises(ActiveRecord::StatementInvalid) do
      Expense.insert!({
        user_id: @user.id,
        category_id: @category.id,
        name: "Inválida",
        amount: -1,
        created_at: Time.current,
        updated_at: Time.current
      })
    end
  end

  test "recusa categoria que pertence a outro usuário" do
    expense = build_expense(category: categories(:moradia_outro))

    assert_not expense.valid?
    assert_includes expense.errors[:category], "precisa pertencer ao mesmo usuário da despesa"
  end

  # --- 13. integridade histórica ----------------------------------------------

  test "não pode ser removida enquanto estiver em alguma rubrica" do
    expense = build_expense
    expense.save
    ledger = @user.ledgers.create!(name: "Janeiro 2026")
    LedgerItem.build_from(ledger: ledger, expense: expense).save!

    assert_not expense.destroy
    assert_predicate expense, :persisted?
  end

  test "não tem estado: nenhuma coluna além de nome, valor e categoria" do
    # Trava a decisão de que despesa não tem estado (arquivada/inativa). Se
    # alguém reintroduzir o conceito, este teste quebra aqui.
    assert_equal %w[id user_id category_id name amount created_at updated_at],
                 Expense.column_names
  end
end
