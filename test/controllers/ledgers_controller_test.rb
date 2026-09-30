require "test_helper"

class LedgersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
  end

  def create_expense(name:, amount:)
    @user.expenses.create!(
      name:, amount: BigDecimal(amount), category: categories(:comunicacao_renato)
    )
  end

  test "cria rubrica copiando a anterior quando a caixa vem marcada" do
    sign_in @user
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    create_expense(name: "Internet", amount: "119.90")
    LedgerItem.build_from(ledger: janeiro, expense: @user.expenses.last).save!

    assert_difference -> { Ledger.count }, 1 do
      post ledgers_path, params: { ledger: { name: "Fevereiro 2026" }, copy_previous: "1" }
    end

    fevereiro = @user.ledgers.recent_first.first
    assert_equal "Fevereiro 2026", fevereiro.name
    assert_equal [ "Internet" ], fevereiro.ledger_items.map(&:name_snapshot)
  end

  test "cria rubrica vazia quando a caixa vem desmarcada" do
    sign_in @user
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    create_expense(name: "Internet", amount: "119.90")
    LedgerItem.build_from(ledger: janeiro, expense: @user.expenses.last).save!

    post ledgers_path, params: { ledger: { name: "Viagem" } }

    assert_equal 0, @user.ledgers.recent_first.first.ledger_items.count
  end

  test "a primeira rubrica é semeada com as despesas do usuário" do
    sign_in @user
    create_expense(name: "Internet", amount: "119.90")

    post ledgers_path, params: { ledger: { name: "Janeiro 2026" }, copy_previous: "1" }

    assert_equal [ "Internet" ], @user.ledgers.first.ledger_items.map(&:name_snapshot)
  end

  test "a rubrica criada passa a ser a selecionada" do
    sign_in @user

    post ledgers_path, params: { ledger: { name: "Janeiro 2026" } }

    assert_equal @user.ledgers.first.id, session[:ledger_id]
    assert_redirected_to root_path(ledger: @user.ledgers.first.id)
  end

  test "nome em branco devolve erro sem criar e sem fechar o modal" do
    sign_in @user

    assert_no_difference -> { Ledger.count } do
      post ledgers_path, params: { ledger: { name: "" } }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_match "rubrica-modal-form", response.body
  end

  test "renomeia" do
    sign_in @user
    ledger = @user.ledgers.create!(name: "Janeiro 2026")

    patch ledger_path(ledger), params: { ledger: { name: "Janeiro de 2026" } }

    assert_equal "Janeiro de 2026", ledger.reload.name
  end

  test "não renomeia rubrica de outro usuário" do
    sign_in @user
    alheia = users(:outro).ledgers.create!(name: "Do outro")

    patch ledger_path(alheia), params: { ledger: { name: "Invadida" } }

    assert_response :not_found
    assert_equal "Do outro", alheia.reload.name
  end

  test "sem sessão não cria nem renomeia" do
    assert_no_difference -> { Ledger.count } do
      post ledgers_path, params: { ledger: { name: "X" } }
    end

    assert_response :redirect
  end

  test "exclui a rubrica e leva as despesas junto" do
  sign_in @user
  ledger = @user.ledgers.create!(name: "Janeiro 2026")
  create_expense(name: "Internet", amount: "119.90")
  LedgerItem.build_from(ledger: ledger, expense: @user.expenses.last).save!

  assert_difference [ -> { Ledger.count }, -> { LedgerItem.count } ], -1 do
    delete ledger_path(ledger)
  end

  assert_redirected_to root_path
  assert Expense.exists?(name: "Internet"), "a despesa do catalogo continua"
end

  test "excluir a rubrica selecionada troca a selecao para a vizinha" do
  sign_in @user
  antiga = @user.ledgers.create!(name: "Antiga")
  nova = @user.ledgers.create!(name: "Nova")
  get root_path(ledger: nova.id)
  assert_equal nova.id, session[:ledger_id]

  delete ledger_path(nova)

  assert_equal antiga.id, session[:ledger_id]
end

  test "não exclui rubrica de outro usuário" do
  sign_in @user
  alheia = users(:outro).ledgers.create!(name: "Do outro")

  assert_no_difference -> { Ledger.count } do
    delete ledger_path(alheia)
  end

  assert_response :not_found
end

# O container do formulário do modal PRECISA ser um <div>, não um
# <turbo-frame>. Um frame escopa a requisição, e como o `create` responde com
# redirect, o Turbo seguiria o destino procurando um frame de mesmo id — e
# nao achando, nao faria nada: "clico em Criar e nada acontece".
test "o formulario do modal nao vive dentro de um turbo-frame" do
  sign_in @user
  @user.ledgers.create!(name: "Janeiro 2026")

  get root_path

  assert_match %r{<div id="rubrica-modal-form">}, response.body
  assert_no_match(/<turbo-frame/, response.body)
end

  # --- sugestão de nome -------------------------------------------------------

  test "sugere o mês seguinte quando a anterior segue Mês Ano" do
    sign_in @user
    @user.ledgers.create!(name: "Janeiro 2026")

    get root_path

    assert_match "Fevereiro 2026", response.body
  end

  test "não sugere nada quando o nome anterior é livre" do
    sign_in @user
    @user.ledgers.create!(name: "Viagem")

    get root_path

    assert_no_match "Fevereiro", response.body
  end
end
