require "test_helper"

class Ledgers::CreateTest < ActiveSupport::TestCase
  setup do
    @user = users(:renato)
    @category = categories(:comunicacao_renato)
  end

  def create_expense(name:, amount:)
    @user.expenses.create!(name:, amount: BigDecimal(amount), category: @category)
  end

  def fill(ledger, rows)
    rows.each do |name, amount, paid|
      expense = create_expense(name:, amount:)
      item = LedgerItem.build_from(ledger:, expense:)
      item.paid = paid if paid
      item.save!
    end
  end

  def snapshots(ledger)
    ledger.ledger_items.to_h { |item| [ item.name_snapshot, item.amount ] }
  end

  # --- 6. cópia da rubrica anterior -------------------------------------------

  test "copia todos os itens da rubrica anterior" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Escola", "1850.00" ], [ "Internet", "119.90" ], [ "Telefone", "89.90" ] ])

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")

    assert_predicate fevereiro, :persisted?
    assert_equal(
      { "Escola" => BigDecimal("1850.00"),
        "Internet" => BigDecimal("119.90"),
        "Telefone" => BigDecimal("89.90") },
      snapshots(fevereiro)
    )
  end

  test "a origem é a rubrica mais recente, não a mais antiga" do
    antiga = @user.ledgers.create!(name: "Antiga")
    fill(antiga, [ [ "Água", "80.00" ] ])
    recente = @user.ledgers.create!(name: "Recente")
    fill(recente, [ [ "Luz", "210.00" ] ])

    nova = Ledgers::Create.call(user: @user, name: "Nova")

    assert_equal [ "Luz" ], nova.ledger_items.map(&:name_snapshot)
  end

  test "a rubrica recém-criada nunca é a própria origem" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")

    assert_equal 1, fevereiro.ledger_items.count
    assert_equal "Internet", fevereiro.ledger_items.first.name_snapshot
  end

  # --- 7. cópia começa sempre como não paga -----------------------------------

  test "itens copiados começam com paid falso, mesmo se a origem estava paga" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Escola", "1850.00", true ], [ "Internet", "119.90", true ] ])
    assert_equal BigDecimal("1969.90"), janeiro.paid_amount

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")

    assert_equal [ false, false ], fevereiro.ledger_items.map(&:paid)
    assert_equal BigDecimal("0"), fevereiro.paid_amount
    assert_equal BigDecimal("1969.90"), fevereiro.remaining_amount
  end

  # --- 8. isolamento entre rubricas -------------------------------------------

  test "alterar a rubrica nova não altera a anterior" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")
    item = fevereiro.ledger_items.first
    item.update!(amount: BigDecimal("999.99"), paid: true, name_snapshot: "Outro nome")

    assert_equal BigDecimal("119.90"), janeiro.reload.total_amount
    assert_equal BigDecimal("0"), janeiro.paid_amount
    assert_equal "Internet", janeiro.ledger_items.first.name_snapshot
    assert_equal 1, janeiro.ledger_items.count
  end

  test "cada item copiado é um registro independente, nunca o mesmo" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")

    assert_equal 2, LedgerItem.count
    assert_not_equal janeiro.ledger_items.first.id, fevereiro.ledger_items.first.id
    assert_equal janeiro.ledger_items.first.expense_id, fevereiro.ledger_items.first.expense_id
  end

  test "a cópia preserva o snapshot mesmo se o cadastro já tiver mudado" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])

    # O cadastro permanente muda DEPOIS que Janeiro nasceu. Copiar não pode
    # reobservar o cadastro — copiar é duplicar o registro, não reler a fonte.
    janeiro.ledger_items.first.expense.update!(amount: BigDecimal("129.90"))

    fevereiro = Ledgers::Create.call(user: @user, name: "Fevereiro 2026")

    assert_equal BigDecimal("119.90"), fevereiro.ledger_items.first.amount
  end

  # --- 12. primeira rubrica ---------------------------------------------------

  test "primeira rubrica não falha e nasce vazia quando não há despesa ativa" do
    primeira = nil

    assert_nothing_raised do
      primeira = Ledgers::Create.call(user: @user, name: "Janeiro 2026")
    end

    assert_predicate primeira, :persisted?
    assert_equal 0, primeira.ledger_items.count
  end

  test "primeira rubrica é semeada com todas as despesas do usuário" do
    create_expense(name: "Escola", amount: "1850.00")
    create_expense(name: "Internet", amount: "119.90")
    create_expense(name: "Telefone", amount: "89.90")

    primeira = Ledgers::Create.call(user: @user, name: "Janeiro 2026")

    assert_equal({ "Escola" => BigDecimal("1850.00"),
                   "Internet" => BigDecimal("119.90"),
                   "Telefone" => BigDecimal("89.90") },
                 snapshots(primeira))
    assert_equal [ false, false, false ], primeira.ledger_items.map(&:paid)
  end

  test "a semeadura da primeira rubrica não atravessa usuários" do
    create_expense(name: "Só do Renato", amount: "10.00")
    users(:outro).expenses.create!(
      name: "Só do Outro", amount: BigDecimal("20.00"), category: categories(:moradia_outro)
    )

    primeira = Ledgers::Create.call(user: @user, name: "Janeiro 2026")

    assert_equal [ "Só do Renato" ], primeira.ledger_items.map(&:name_snapshot)
  end

  # --- escolha explícita da origem --------------------------------------------

  test "copy_from nil cria rubrica vazia mesmo existindo rubrica anterior" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])

    viagem = Ledgers::Create.call(user: @user, name: "Viagem", copy_from: nil)

    assert_equal 0, viagem.ledger_items.count
  end

  test "copy_from com uma rubrica específica copia daquela rubrica" do
    janeiro = @user.ledgers.create!(name: "Janeiro 2026")
    fill(janeiro, [ [ "Internet", "119.90" ] ])
    marco = @user.ledgers.create!(name: "Março 2026")
    fill(marco, [ [ "Escola", "1850.00" ] ])

    copia = Ledgers::Create.call(user: @user, name: "Casa nova", copy_from: janeiro)

    assert_equal [ "Internet" ], copia.ledger_items.map(&:name_snapshot)
  end

  test "recusa copiar de rubrica de outro usuário" do
    alheia = users(:outro).ledgers.create!(name: "Do outro")

    assert_raises(ArgumentError) do
      Ledgers::Create.call(user: @user, name: "Minha", copy_from: alheia)
    end
    assert_not @user.ledgers.exists?(name: "Minha")
  end

  test "recusa origem de tipo inesperado" do
    assert_raises(ArgumentError) do
      Ledgers::Create.call(user: @user, name: "Minha", copy_from: :qualquer_coisa)
    end
  end

  test "exige nome" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Ledgers::Create.call(user: @user, name: "")
    end
    assert_equal 0, @user.ledgers.count
  end
end
