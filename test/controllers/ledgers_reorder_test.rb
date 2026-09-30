require "test_helper"

# Reordenação das despesas de uma rubrica.
class LedgersReorderTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    @itens = %w[Escola Internet Telefone].map do |nome|
      item = LedgerItem.build_from(
        ledger: @ledger,
        expense: @user.expenses.create!(
          name: nome, amount: BigDecimal("10.00"), category: categories(:comunicacao_renato)
        )
      )
      item.save!
      item
    end
  end

  def nomes_na_ordem
    @ledger.ledger_items.reload.map(&:name_snapshot)
  end

  test "despesa nova entra no fim da lista" do
    assert_equal %w[Escola Internet Telefone], nomes_na_ordem
    assert_equal [ 1, 2, 3 ], @ledger.ledger_items.map(&:position)
  end

  test "regrava a ordem conforme os ids recebidos" do
    sign_in @user
    escola, internet, telefone = @itens

    patch reorder_ledger_path(@ledger),
          params: { ids: [ telefone.id, escola.id, internet.id ] },
          as: :json

    assert_response :no_content
    assert_equal %w[Telefone Escola Internet], nomes_na_ordem
    assert_equal [ 1, 2, 3 ], @ledger.ledger_items.map(&:position)
  end

  test "a ordem sobrevive a uma nova leitura" do
    sign_in @user
    escola, internet, telefone = @itens

    patch reorder_ledger_path(@ledger),
          params: { ids: [ internet.id, escola.id, telefone.id ] },
          as: :json

    get root_path(ledger: @ledger.id)

    assert_equal %w[Internet Escola Telefone], nomes_na_ordem
  end

  test "id de outra rubrica é ignorado" do
    sign_in @user
    escola, internet, telefone = @itens
    alheio = users(:outro).ledgers.create!(name: "Do outro")
    item_alheio = LedgerItem.create!(
      ledger: alheio,
      expense: users(:outro).expenses.create!(
        name: "Alheia", amount: BigDecimal("1.00"), category: categories(:moradia_outro)
      ),
      name_snapshot: "Alheia", category_name_snapshot: "Moradia",
      amount: BigDecimal("1.00"), paid: false
    )

    patch reorder_ledger_path(@ledger),
          params: { ids: [ item_alheio.id, telefone.id, escola.id, internet.id ] },
          as: :json

    assert_response :no_content
    assert_equal %w[Telefone Escola Internet], nomes_na_ordem
  end

  # Aba desatualizada: a lista enviada não conhece uma despesa recém-criada. O
  # que ela não mandou vai para o fim, em vez de a ordem quebrar.
  test "ids que o cliente não mandou ficam no fim" do
    sign_in @user
    escola, internet, telefone = @itens

    patch reorder_ledger_path(@ledger),
          params: { ids: [ escola.id ] },
          as: :json

    assert_equal %w[Escola Internet Telefone], nomes_na_ordem
  end

# A ordem enviada e a ordem GRAVADA. Um id repetido, um buraco na sequencia ou
# uma posicao duplicada quebrariam a lista de um jeito que so aparece depois,
# ao recarregar.
test "a ordem final e completa, sem duplicatas e sem buracos" do
  sign_in @user
  escola, internet, telefone = @itens

  patch reorder_ledger_path(@ledger),
        params: { ids: [ telefone.id, escola.id, internet.id ] },
        as: :json

  posicoes = @ledger.ledger_items.reload.map(&:position).sort
  assert_equal [ 1, 2, 3 ], posicoes, "as posicoes precisam ser 1..N sem buraco"
  assert_equal posicoes.uniq, posicoes, "posicao repetida torna a ordem indeterministica"
  assert_equal 3, @ledger.ledger_items.map(&:id).uniq.size
end

test "id repetido na lista nao duplica nem some com a despesa" do
  sign_in @user
  escola, _internet, _telefone = @itens

  patch reorder_ledger_path(@ledger),
        params: { ids: [ escola.id, escola.id ] },
        as: :json

  assert_equal 3, @ledger.ledger_items.reload.count
  assert_equal [ 1, 2, 3 ], @ledger.ledger_items.map(&:position).sort
end

  test "a lista continua ordenada por position, não por id" do
    sign_in @user
    escola, internet, telefone = @itens

    patch reorder_ledger_path(@ledger),
          params: { ids: [ telefone.id, internet.id, escola.id ] },
          as: :json

    # A ordem pedida contraria o id de propósito: se alguém voltar a ordenar por
    # `id`, este teste quebra.
    assert_equal [ telefone.id, internet.id, escola.id ], @ledger.ledger_items.map(&:id)
  end

  test "não reordena rubrica de outro usuário" do
    sign_in @user
    alheia = users(:outro).ledgers.create!(name: "Do outro")

    patch reorder_ledger_path(alheia), params: { ids: [] }, as: :json

    assert_response :not_found
  end

  test "sem sessão não reordena" do
    escola, internet, telefone = @itens

    patch reorder_ledger_path(@ledger),
          params: { ids: [ telefone.id, escola.id, internet.id ] },
          as: :json

    # Requisição JSON: o Devise responde 401, não redirect.
    assert_response :unauthorized
    assert_equal %w[Escola Internet Telefone], nomes_na_ordem
  end
end
