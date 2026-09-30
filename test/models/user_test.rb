require "test_helper"

class UserTest < ActiveSupport::TestCase
  # O cancelamento de conta do Devise chama `resource.destroy`. Com despesas
  # protegidas por `restrict_with_error` e por FK, a exclusão só funciona se as
  # rubricas (e seus itens) saírem ANTES das despesas — é a ordem de declaração
  # das associações em User. Este teste existe para travar essa ordem: se
  # alguém reordenar as `has_many`, ele quebra aqui em vez de quebrar em
  # produção, no botão "Cancelar minha conta".
  test "apagar a conta remove todo o domínio sem esbarrar na proteção de histórico" do
    user = users(:renato)
    category = user.categories.create!(name: "Moradia Extra")
    expense = user.expenses.create!(name: "Internet", amount: BigDecimal("119.90"), category:)

    janeiro = Ledgers::Create.call(user:, name: "Janeiro 2026")
    assert_equal 1, janeiro.ledger_items.count

    assert_difference -> { User.count }, -1 do
      user.destroy
    end

    assert_nil User.find_by(id: user.id)
    assert_nil Expense.find_by(id: expense.id)
    assert_nil Category.find_by(id: category.id)
    assert_nil Ledger.find_by(id: janeiro.id)
    assert_equal 0, LedgerItem.where(expense_id: expense.id).count
  end

  # O rolify NÃO aceita `dependent:` — ele filtra essa opção ao montar a
  # associação has_and_belongs_to_many (ver vendor/gems/rolify/lib/rolify.rb).
  # Então o vínculo de perfil só sai junto se a FK tiver `on_delete: :cascade`,
  # que é o que a migração declara. Sem ela, este teste deixa uma linha órfã em
  # `users_roles` e falha.
  test "apagar a conta leva os vínculos de perfil junto" do
    user = users(:renato)
    user.add_role(Profiles::ADMIN)
    user_id = user.id

    assert_difference -> { vinculos_de_perfil }, -1 do
      user.destroy
    end

    assert_equal 0, vinculos_de_perfil(user_id)
  end

  test "apagar um usuário não afeta o domínio do outro" do
    renato = users(:renato)
    outro = users(:outro)
    expense_do_outro = outro.expenses.create!(
      name: "Internet", amount: BigDecimal("119.90"), category: categories(:moradia_outro)
    )

    renato.destroy

    assert Expense.exists?(expense_do_outro.id)
    assert Category.exists?(categories(:moradia_outro).id)
  end

  private

  # SQL cru, e não `Role.joins(:users)`: o que se quer observar é a LINHA da
  # tabela de junção, e ela não tem model próprio (o rolify cria uma associação
  # has_and_belongs_to_many, não um model).
  def vinculos_de_perfil(user_id = nil)
    sql = +"SELECT COUNT(*) FROM users_roles"
    sql << " WHERE user_id = #{user_id.to_i}" if user_id
    ActiveRecord::Base.connection.select_value(sql).to_i
  end
end
