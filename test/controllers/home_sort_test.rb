require "test_helper"

# Modos de ordenação da lista de despesas.
class HomeSortTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")

  # Nomes escolhidos para as TRES ordens serem diferentes entre si — se
  # coincidissem, o teste passaria sem provar nada.
  [ [ "Escola", "1850.00", "Educação" ],
    [ "Internet", "119.90", "Assinaturas" ],
    [ "Aluguel", "2500.00", "Transporte" ] ].each do |nome, valor, categoria|
    categoria = @user.categories.find_or_create_by!(name: categoria)
    LedgerItem.build_from(
      ledger: @ledger,
      expense: @user.expenses.create!(name: nome, amount: BigDecimal(valor), category: categoria)
    ).save!
  end
end

  # Nokogiri, e não regex: o atributo `data-action="click->modal#open"` tem um
  # `>` dentro, e um `[^>]*` pára ali e captura lixo em vez do nome.
  def nomes_na_tela
    Nokogiri::HTML(response.body).css(".ds-expense-row__name").map { |no| no.text.strip }
  end

  test "sem parâmetro, usa a ordem manual" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    assert_equal %w[Escola Internet Aluguel], nomes_na_tela
  end

  test "sort=cost ordena pelo maior valor primeiro" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "cost")

    assert_equal %w[Aluguel Escola Internet], nomes_na_tela
  end

  test "sort=category ordena pelo nome da categoria" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "category")

    assert_equal %w[Internet Escola Aluguel], nomes_na_tela
  end

  # O ponto central: ordenar é um jeito de OLHAR, não uma reordenação.
  test "ordenar por custo NÃO altera a ordem manual gravada" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "cost")

    assert_equal [ 1, 2, 3 ], @ledger.ledger_items.reload.map(&:position)
    assert_equal %w[Escola Internet Aluguel], @ledger.ledger_items.map(&:name_snapshot)
  end

  test "a alça de arrasto some nos modos calculados" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "cost")
    assert_no_match "data-drag-handle", response.body

    # Explícito de propósito: a sessão lembra "cost" da requisição anterior —
    # que é o comportamento desejado, e faria este assert passar por engano.
    get root_path(ledger: @ledger.id, sort: "manual")
    assert_match "data-drag-handle", response.body
  end

  test "modo desconhecido cai na ordem manual" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "qualquer_coisa")

    assert_equal %w[Escola Internet Aluguel], nomes_na_tela
  end

  test "a escolha fica na sessão para a próxima visita" do
    sign_in @user

    get root_path(ledger: @ledger.id, sort: "cost")
    get root_path(ledger: @ledger.id)

    assert_equal %w[Aluguel Escola Internet], nomes_na_tela
  end

  # Criar uma despesa redesenha a lista por Turbo Stream, sem passar pelo
  # HomeController: se o modo não estivesse na sessão, a lista voltaria para a
  # ordem manual no meio de uma ordenação por custo.
  test "criar uma despesa preserva o modo de ordenação" do
    sign_in @user
    get root_path(ledger: @ledger.id, sort: "cost")

    post ledger_items_path,
         params: { ledger_id: @ledger.id,
                   ledger_item: { name: "Telefone", amount: "89.90",
                                  category_name: "Comunicação" } },
         as: :turbo_stream

    # Telefone entra no fim da ORDEM MANUAL (posição 4), mas aparece por último
    # aqui porque o modo é "Custo" — que é exatamente o ponto do teste.
    assert_equal %w[Aluguel Escola Internet Telefone], nomes_na_tela
  end
end
