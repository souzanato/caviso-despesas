require "test_helper"

class LedgerItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    expense = @user.expenses.create!(
      name: "Internet", amount: BigDecimal("119.90"), category: categories(:comunicacao_renato)
    )
    @item = LedgerItem.build_from(ledger: @ledger, expense: expense)
    @item.save!
  end

  test "marca como paga e responde em turbo stream" do
    sign_in @user

    patch ledger_item_path(@item),
          params: { ledger_item: { paid: "1" } },
          as: :turbo_stream

    assert_response :success
    assert @item.reload.paid
  end

  test "desmarca" do
    sign_in @user
    @item.update!(paid: true)

    patch ledger_item_path(@item),
          params: { ledger_item: { paid: "0" } },
          as: :turbo_stream

    assert_response :success
    assert_not @item.reload.paid
  end

  test "a resposta substitui a linha e o resumo" do
    sign_in @user

    patch ledger_item_path(@item),
          params: { ledger_item: { paid: "1" } },
          as: :turbo_stream

    # Recarregar a tela inteira na ação mais frequente faria a lista piscar.
    assert_match "ledger-summary", response.body
    assert_match dom_id(@item), response.body
  end

  test "a resposta atualiza o saldo da rubrica no picker" do
    sign_in @user

    patch ledger_item_path(@item), params: { ledger_item: { paid: "1" } }, as: :turbo_stream

    assert_match dom_id(@ledger, :picker_amount), response.body
  end

  # `turbo_stream.replace` troca o elemento INTEIRO pelo HTML do parcial. Se o
  # parcial nao devolver o proprio id, o primeiro replace funciona e destroi o
  # alvo — e o segundo nao acha mais nada. Foi o que fez o valor diminuir ao
  # marcar pago e nao voltar ao desmarcar.
  test "o replace do saldo devolve o alvo, entao e repetivel" do
    sign_in @user

    patch ledger_item_path(@item), params: { ledger_item: { paid: "1" } }, as: :turbo_stream
    assert_match %r{<span class="ds-picker__amount" id="#{dom_id(@ledger, :picker_amount)}">},
               response.body

    patch ledger_item_path(@item), params: { ledger_item: { paid: "0" } }, as: :turbo_stream
    assert_match %r{<span class="ds-picker__amount" id="#{dom_id(@ledger, :picker_amount)}">},
               response.body
    assert_match "119,90", response.body
  end

  test "sem sessão não altera nada" do
    patch ledger_item_path(@item),
          params: { ledger_item: { paid: "1" } },
          as: :turbo_stream

    assert_response :redirect
    assert_not @item.reload.paid
  end

  test "não alcança item de rubrica de outro usuário" do
    sign_in @user
    alheio = LedgerItem.create!(
      ledger: users(:outro).ledgers.create!(name: "Do outro"),
      expense: users(:outro).expenses.create!(
        name: "Internet", amount: BigDecimal("50.00"), category: categories(:moradia_outro)
      ),
      name_snapshot: "Internet", category_name_snapshot: "Moradia",
      amount: BigDecimal("50.00"), paid: false
    )

    patch ledger_item_path(alheio),
          params: { ledger_item: { paid: "1" } },
          as: :turbo_stream

    assert_response :not_found
    assert_not alheio.reload.paid
  end
end
