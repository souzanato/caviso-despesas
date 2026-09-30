require "test_helper"

# Criação de despesa dentro de uma rubrica — [expense-modal] §10.
class LedgerItemsCreateTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
  end

  def create_item(name:, amount:, category_name:)
    post ledger_items_path,
         params: { ledger_id: @ledger.id,
                   ledger_item: { name:, amount:, category_name: } },
         as: :turbo_stream
  end

  test "cria a despesa e o item na rubrica, com os snapshots do momento" do
    sign_in @user

    assert_difference [ -> { Expense.count }, -> { LedgerItem.count } ], 1 do
      create_item(name: "Escola", amount: "1850.00", category_name: "Educação")
    end

    assert_response :success
    item = @ledger.ledger_items.last
    assert_equal "Escola", item.name_snapshot
    assert_equal BigDecimal("1850.00"), item.amount
    assert_equal "Educação", item.category_name_snapshot
    assert_not item.paid, "despesa nova entra como não paga"
  end

  test "cria a categoria quando o nome digitado ainda não existe" do
    sign_in @user

    assert_difference -> { @user.categories.count }, 1 do
      create_item(name: "Internet", amount: "119.90", category_name: "Moradia Nova")
    end

    assert_equal "Moradia Nova", @ledger.ledger_items.last.expense.category.name
  end

  test "reaproveita a categoria existente sem diferenciar maiúsculas" do
    sign_in @user

    assert_no_difference -> { @user.categories.count } do
      create_item(name: "Internet", amount: "119.90", category_name: "comunicação")
    end

    assert_equal categories(:comunicacao_renato).id,
                 @ledger.ledger_items.last.expense.category_id
  end

  # É o que torna "despesa reutilizável" verdade: lançar a mesma despesa em
  # outra rubrica não deve inchar o catálogo com duplicatas.
  test "reaproveita a despesa quando nome, valor e categoria são iguais" do
    sign_in @user
    create_item(name: "Internet", amount: "119.90", category_name: "Comunicação")

    fevereiro = @user.ledgers.create!(name: "Fevereiro 2026")
    @ledger = fevereiro

    assert_no_difference -> { Expense.count } do
      create_item(name: "Internet", amount: "119.90", category_name: "Comunicação")
    end

    assert_equal 1, fevereiro.ledger_items.count
  end

  # A regra do produto: mesmo título com valor diferente é OUTRA despesa.
  test "valor diferente cria uma despesa nova" do
    sign_in @user
    create_item(name: "Internet", amount: "119.90", category_name: "Comunicação")

    assert_difference -> { Expense.count }, 1 do
      create_item(name: "Internet", amount: "129.90", category_name: "Comunicação")
    end
  end

  test "nome em branco devolve erro sem criar nada e sem fechar o modal" do
    sign_in @user

    assert_no_difference [ -> { Expense.count }, -> { LedgerItem.count } ] do
      create_item(name: "  ", amount: "10.00", category_name: "Comunicação")
    end

    assert_response :unprocessable_entity
    assert_match "expense-form", response.body
  end

  # O picker mostra o "falta" da rubrica selecionada. Se a resposta nao o
  # substituir, ele fica com o valor antigo ate recarregar a pagina — foi
  # exatamente o defeito relatado.
  test "a resposta atualiza o saldo da rubrica no picker" do
    sign_in @user

    create_item(name: "Escola", amount: "1850.00", category_name: "Educacao")

    assert_match dom_id(@ledger, :picker_amount), response.body
    assert_match "1.850,00", response.body
  end

# Categoria em branco e erro de VALIDACAO, nao excecao. Antes disto, um
# envio sem categoria derrubava com 500 — e a pagina de erro invalidava a
# sessao, fazendo o reenvio falhar por CSRF logo depois.
test "categoria em branco devolve erro em vez de derrubar" do
  sign_in @user

  assert_no_difference [ -> { Expense.count }, -> { LedgerItem.count } ] do
    create_item(name: "Google One", amount: "96.99", category_name: "")
  end

  assert_response :unprocessable_entity
  assert_match "expense-form", response.body
  assert_match "Categoria não pode ficar em branco", response.body
end

  test "o item nasce na rubrica informada" do
    sign_in @user
    outra = @user.ledgers.create!(name: "Viagem")

    post ledger_items_path,
         params: { ledger_id: outra.id,
                   ledger_item: { name: "Hotel", amount: "400.00", category_name: "Lazer" } },
         as: :turbo_stream

    assert_equal 1, outra.reload.ledger_items.count
    assert_equal 0, @ledger.reload.ledger_items.count
  end

  test "não cria em rubrica de outro usuário" do
    sign_in @user
    alheia = users(:outro).ledgers.create!(name: "Do outro")

    assert_no_difference -> { LedgerItem.count } do
      post ledger_items_path,
           params: { ledger_id: alheia.id,
                     ledger_item: { name: "X", amount: "1.00", category_name: "Y" } },
           as: :turbo_stream
    end

    assert_response :not_found
  end

  test "sem sessão não cria nada" do
    assert_no_difference -> { LedgerItem.count } do
      create_item(name: "Escola", amount: "10.00", category_name: "Educação")
    end

    assert_response :redirect
  end
end
