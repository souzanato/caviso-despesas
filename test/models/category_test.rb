require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup { @user = users(:renato) }

  # --- 1. criação de categoria ------------------------------------------------

  test "cria categoria válida para um usuário" do
    category = @user.categories.create!(name: "Educação")

    assert_predicate category, :persisted?
    assert_equal @user.id, category.user_id
  end

  test "exige nome" do
    category = @user.categories.build(name: "")

    assert_not category.valid?
    assert_includes category.errors[:name], "não pode ficar em branco"
  end

  test "nome é único por usuário, ignorando maiúsculas" do
    duplicada = @user.categories.build(name: "moradia")

    assert_not duplicada.valid?
    assert_includes duplicada.errors[:name], "já está em uso"
  end

  test "o mesmo nome é permitido para outro usuário" do
    # categories.yml já tem "Moradia" para os dois usuários.
    assert users(:outro).categories.exists?(name: "Moradia")
    assert users(:renato).categories.exists?(name: "Moradia")

    assert_nothing_raised do
      users(:outro).categories.create!(name: "Transporte")
    end
  end

  test "normaliza espaços em volta e no meio do nome" do
    category = @user.categories.create!(name: "  Cuidados   Pessoais  ")

    assert_equal "Cuidados Pessoais", category.reload.name
  end

  # --- garantias que precisam ser do banco, não do Ruby -----------------------

  test "o banco recusa duplicata por caixa mesmo sem passar pelo model" do
    # `insert!` pula validações: quem barra aqui é o índice funcional.
    assert_raises(ActiveRecord::RecordNotUnique) do
      Category.insert!({
        user_id: @user.id,
        name: "MORADIA",
        created_at: Time.current,
        updated_at: Time.current
      })
    end
  end

  test "não pode ser removida enquanto tiver despesas" do
    category = @user.categories.create!(name: "Temporária")
    category.expenses.create!(user: @user, name: "Internet", amount: BigDecimal("119.90"))

    assert_not category.destroy
    assert_predicate category, :persisted?
  end

  # --- seeds ------------------------------------------------------------------

  test "seed_defaults_for! é idempotente e cobre a lista do produto" do
    user = users(:outro)

    Category.seed_defaults_for!(user)
    primeira_contagem = user.categories.count
    assert_equal Category::DEFAULTS.size, primeira_contagem

    Category.seed_defaults_for!(user)

    assert_equal primeira_contagem, user.categories.reload.count
  end

  test "seed_defaults_for! não duplica categoria já existente com outra caixa" do
    # Usuário novo, sem categorias: o cenário é "já existe uma com caixa
    # diferente da lista padrão".
    user = User.create!(
      email: "seed@example.com", username: "seed",
      full_name: "Usuário Seed", password: "senha12345"
    )
    user.categories.create!(name: "moradia")

    Category.seed_defaults_for!(user)

    assert_equal 1, user.categories.where("lower(name) = ?", "moradia").count
    assert_equal Category::DEFAULTS.size, user.categories.count
  end
end
