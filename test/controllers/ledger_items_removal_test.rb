require "test_helper"

# Remover uma despesa da rubrica e desfazer — [snackbar] §8.
class LedgerItemsRemovalTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    @expense = @user.expenses.create!(
      name: "Internet", amount: BigDecimal("119.90"), category: categories(:comunicacao_renato)
    )
    @item = LedgerItem.build_from(ledger: @ledger, expense: @expense)
    @item.paid = true
    @item.save!
  end

  test "remove o item da rubrica" do
    sign_in @user

    assert_difference -> { LedgerItem.count }, -1 do
      delete ledger_item_path(@item), as: :turbo_stream
    end

    assert_response :success
    assert_empty @ledger.reload.ledger_items
  end

  test "a despesa continua no cadastro" do
    sign_in @user

    delete ledger_item_path(@item), as: :turbo_stream

    assert Expense.exists?(@expense.id), "remover da rubrica não apaga a despesa"
  end

  test "não afeta as outras rubricas que usam a mesma despesa" do
    sign_in @user
    fevereiro = @user.ledgers.create!(name: "Fevereiro 2026")
    outro = LedgerItem.build_from(ledger: fevereiro, expense: @expense)
    outro.save!

    delete ledger_item_path(@item), as: :turbo_stream

    assert_equal 1, fevereiro.reload.ledger_items.count
  end

  test "a resposta oferece desfazer e não pede confirmação antes" do
    sign_in @user

    delete ledger_item_path(@item), as: :turbo_stream

    assert_match I18n.t("shared.undo"), response.body
    assert_match "snackbar", response.body
  end

  test "a lista some quando era o último item" do
    sign_in @user

    delete ledger_item_path(@item), as: :turbo_stream

    assert_match "ds-empty-state", response.body
  end

  # --- desfazer ---------------------------------------------------------------

  test "desfazer recria o item com os mesmos snapshots, inclusive pago" do
    sign_in @user
    delete ledger_item_path(@item), as: :turbo_stream

    assert_difference -> { LedgerItem.count }, 1 do
      post restore_ledger_items_path, params: undo_params_from(response.body), as: :turbo_stream
    end

    restaurado = @ledger.ledger_items.reload.last
    assert_equal "Internet", restaurado.name_snapshot
    assert_equal "Comunicação", restaurado.category_name_snapshot
    assert_equal BigDecimal("119.90"), restaurado.amount
    assert restaurado.paid, "o estado de pagamento volta junto"
    assert_equal @expense.id, restaurado.expense_id
  end

  test "desfazer não alcança rubrica de outro usuário" do
    sign_in @user
    delete ledger_item_path(@item), as: :turbo_stream
    undo = undo_params_from(response.body)
                .merge(ledger_id: users(:outro).ledgers.create!(name: "Alheia").id)

    assert_no_difference -> { LedgerItem.count } do
      post restore_ledger_items_path, params: undo, as: :turbo_stream
    end

    assert_response :not_found
  end

  test "sem sessão não remove nada" do
    assert_no_difference -> { LedgerItem.count } do
      delete ledger_item_path(@item), as: :turbo_stream
    end

    assert_response :redirect
  end

  private

  # Lê os campos do formulário de desfazer direto do HTML respondido.
  #
  # É de propósito: prova que os snapshots realmente viajam no corpo do
  # snackbar, em vez de confiar num estado interno do controller. O que o
  # navegador enviaria é exatamente isto.
  def undo_params_from(body)
    Nokogiri::HTML(body)
            .css("form[action='#{restore_ledger_items_path}'] input[type=hidden]")
            .each_with_object({}) do |input, acc|
      next if input["name"] == "authenticity_token"

      acc[input["name"]] = input["value"]
    end
  end
end
