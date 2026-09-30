require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @category = categories(:comunicacao_renato)
  end

  # --- autenticação -----------------------------------------------------------

  test "sem sessão, qualquer ação redireciona para o login" do
    get categories_path
    assert_redirected_to new_user_session_path
  end

  # --- index ------------------------------------------------------------------

  test "index lista as categorias do usuário" do
    sign_in @user

    get categories_path

    assert_response :success
    assert_select ".ds-page-header__title", t_pt("categories.index.title")
    assert_select ".ds-category-list__row", @user.categories.count
    assert_select ".ds-category-badge", @user.categories.count
  end

  test "index não mostra categoria de outro usuário" do
    sign_in @user
    alheia = categories(:moradia_outro)

    get categories_path

    assert_response :success
    # Conferir o nome "Moradia" não serviria: o Renato TEM a própria "Moradia".
    # O que não pode aparecer é a linha — nem os links de ação — da categoria
    # que pertence ao outro usuário.
    assert_no_match %r{/categories/#{alheia.id}/edit}, response.body
    assert_select ".ds-category-list__row", @user.categories.count
  end

  test "index vazio mostra o empty state e o CTA" do
    vazio = User.create!(
      email: "vazio@example.com", username: "vazio",
      full_name: "Sem Categorias", password: "senha12345"
    )
    # Vazio de CATEGORIAS, não de perfil: sem o perfil o gate barra antes de a
    # tela existir, e o teste deixaria de medir o que quer medir.
    vazio.add_role(Profiles::ADMIN)
    sign_in vazio

    get categories_path

    assert_response :success
    assert_select ".ds-empty-state", 1
    assert_select ".ds-category-list", 0
    assert_select ".ds-empty-state a[href=?]", new_category_path
  end

  # --- create -----------------------------------------------------------------

  test "new renderiza o formulário" do
    sign_in @user

    get new_category_path

    assert_response :success
    assert_select ".ds-field__input"
    assert_select ".ds-btn--primary"
  end

  test "create cria a categoria do usuário logado" do
    sign_in @user

    assert_difference -> { @user.categories.count }, 1 do
      post categories_path, params: { category: { name: "Transporte" } }
    end

    assert_redirected_to categories_path
    assert_equal @user.id, Category.find_by(name: "Transporte").user_id
  end

  test "create com nome em branco devolve 422 e não cria" do
    sign_in @user

    assert_no_difference -> { Category.count } do
      post categories_path, params: { category: { name: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".ds-alert--error"
  end

  test "create recusa nome já usado pelo mesmo usuário, ignorando caixa" do
    sign_in @user

    assert_no_difference -> { Category.count } do
      post categories_path, params: { category: { name: "moradia" } }
    end

    assert_response :unprocessable_entity
    assert_select ".ds-alert--error"
  end

  test "o mesmo nome é aceito para outro usuário" do
    # `outro` é o fixture SEM perfil, e continua sendo — o perfil aqui é
    # concedido só para este teste, que é sobre unicidade de categoria escopada
    # por usuário, não sobre o gate.
    users(:outro).add_role(Profiles::ADMIN)
    sign_in users(:outro)

    assert_difference -> { users(:outro).categories.count }, 1 do
      post categories_path, params: { category: { name: "Lazer Novo" } }
    end

    assert_redirected_to categories_path
  end

  # --- update -----------------------------------------------------------------

  test "edit renderiza o formulário preenchido" do
    sign_in @user

    get edit_category_path(@category)

    assert_response :success
    assert_select ".ds-field__input[value=?]", @category.name
  end

  test "update altera o nome" do
    sign_in @user

    patch category_path(@category), params: { category: { name: "Comunicação e Internet" } }

    assert_redirected_to categories_path
    assert_equal "Comunicação e Internet", @category.reload.name
  end

  test "update com nome em branco devolve 422 e não altera" do
    sign_in @user
    original = @category.name

    patch category_path(@category), params: { category: { name: "" } }

    assert_response :unprocessable_entity
    assert_equal original, @category.reload.name
  end

  # --- destroy ----------------------------------------------------------------

  test "destroy exclui categoria sem despesas" do
    sign_in @user
    solta = @user.categories.create!(name: "Categoria Solta")

    assert_difference -> { Category.count }, -1 do
      delete category_path(solta)
    end

    assert_redirected_to categories_path
    follow_redirect!
    assert_select ".ds-alert--notice"
  end

  test "destroy é recusado quando a categoria está em uso por despesas" do
    sign_in @user
    @user.expenses.create!(name: "Internet", amount: BigDecimal("119.90"), category: @category)

    assert_no_difference -> { Category.count } do
      delete category_path(@category)
    end

    assert_redirected_to categories_path
    follow_redirect!
    assert_select ".ds-alert--error"
    assert Category.exists?(@category.id)
  end

  # --- escopo por usuário -----------------------------------------------------

  test "não é possível editar categoria de outro usuário" do
    sign_in @user

    get edit_category_path(categories(:moradia_outro))

    assert_response :not_found
  end

  test "não é possível excluir categoria de outro usuário" do
    sign_in @user

    assert_no_difference -> { Category.count } do
      delete category_path(categories(:moradia_outro))
    end

    assert_response :not_found
  end

  private

  def t_pt(chave, **opts)
    I18n.t(chave, **opts)
  end
end
