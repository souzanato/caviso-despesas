require "test_helper"

# Edição do que a rubrica registra de uma despesa — [expense-modal] §10.
#
# A edição mexe nos SNAPSHOTS do item, nunca no cadastro da despesa. É o que a
# especificação chama de "valor próprio daquele período".
class LedgerItemsDetailsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    @expense = @user.expenses.create!(
      name: "Internet", amount: BigDecimal("119.90"), category: categories(:comunicacao_renato)
    )
    @item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    @item.save!
  end

  def edit(name:, amount:, category_name:)
    patch details_ledger_item_path(@item),
          params: { ledger_item: { name_snapshot: name, amount:, category_name: } }
  end

  test "edita nome, valor e categoria do item" do
    sign_in @user

    edit(name: "Internet Fibra", amount: "129.90", category_name: "Comunicação")

    @item.reload
    assert_equal "Internet Fibra", @item.name_snapshot
    assert_equal BigDecimal("129.90"), @item.amount
    assert_equal "Comunicação", @item.category_name_snapshot
  end

  test "a despesa do cadastro NÃO é alterada" do
    sign_in @user

    edit(name: "Internet Fibra", amount: "129.90", category_name: "Comunicação")

    assert_equal "Internet", @expense.reload.name
    assert_equal BigDecimal("119.90"), @expense.amount
  end

  test "editar uma rubrica não altera a outra" do
    sign_in @user
    fevereiro = @user.ledgers.create!(name: "Fevereiro 2026")
    outro = LedgerItem.build_from(ledger: fevereiro, expense: @expense)
    outro.save!

    edit(name: "Internet Fibra", amount: "129.90", category_name: "Comunicação")

    assert_equal "Internet", outro.reload.name_snapshot
    assert_equal BigDecimal("119.90"), outro.amount
  end

  test "a categoria digitada que não existe é criada" do
    sign_in @user

    assert_difference -> { @user.categories.count }, 1 do
      edit(name: "Internet", amount: "119.90", category_name: "Categoria Nova")
    end

    assert_equal "Categoria Nova", @item.reload.category_name_snapshot
  end

  test "valor negativo é recusado, avisa e não grava nada" do
    sign_in @user

    edit(name: "Internet Alterada", amount: "-1", category_name: "Comunicação")

    assert_redirected_to root_path(ledger: @ledger.id)
    assert_equal "Valor deve ser maior ou igual a 0", flash[:alert]

    # `update!` é atômico: nem o nome válido entrou.
    assert_equal "Internet", @item.reload.name_snapshot
    assert_equal BigDecimal("119.90"), @item.amount
  end

  test "não edita item de rubrica de outro usuário" do
    sign_in @user
    alheio = LedgerItem.create!(
      ledger: users(:outro).ledgers.create!(name: "Do outro"),
      expense: users(:outro).expenses.create!(
        name: "Internet", amount: BigDecimal("50.00"), category: categories(:moradia_outro)
      ),
      name_snapshot: "Internet", category_name_snapshot: "Moradia",
      amount: BigDecimal("50.00"), paid: false
    )

    patch details_ledger_item_path(alheio),
          params: { ledger_item: { name_snapshot: "Invadida", amount: "1.00",
                                   category_name: "Moradia" } }

    assert_response :not_found
    assert_equal "Internet", alheio.reload.name_snapshot
  end

  test "sem sessão não edita" do
    edit(name: "Internet Fibra", amount: "129.90", category_name: "Comunicação")

    assert_response :redirect
    assert_equal "Internet", @item.reload.name_snapshot
  end
end
