require "test_helper"

# A pergunta que o gate do app faz em toda request.
class UserPolicyTest < ActiveSupport::TestCase
  test "quem tem o perfil pode" do
    user = users(:renato)
    user.add_role(Profiles::ADMIN)

    assert UserPolicy.new(user, user).access_app?
  end

  test "quem não tem o perfil não pode" do
    assert_not UserPolicy.new(users(:outro), users(:outro)).access_app?
  end

  test "sem usuário não pode" do
    # `current_user` é nil em rotas públicas. O gate roda depois do
    # `authenticate_user!`, mas a policy não deve explodir se for perguntada
    # antes — é o tipo de acoplamento que só aparece no dia em que a ordem dos
    # filtros mudar.
    assert_not UserPolicy.new(nil, nil).access_app?
  end

  test "perfil preso a um registro não vale como perfil do app" do
    user = users(:renato)

    # `resourcify` não é usado hoje, então a validação do `Role` recusaria um
    # resource_type — daí o SQL cru. O que se prova aqui é a CONSULTA do gate:
    # `has_role?` procura o perfil global (resource_type nulo), então um perfil
    # preso a um registro não abre o app. Sem esta garantia, bastaria alguém
    # trocar `has_role?` por `roles.any?` para um "admin da rubrica X" virar
    # "admin do app".
    role_id = connection.select_value(<<~SQL)
      INSERT INTO roles (name, resource_type, resource_id, created_at, updated_at)
      VALUES ('admin', 'Ledger', #{user.ledgers.create!(name: "Janeiro 2026").id}, now(), now())
      RETURNING id
    SQL
    connection.execute("INSERT INTO users_roles (user_id, role_id) VALUES (#{user.id}, #{role_id.to_i})")

    assert_equal 1, user.reload.roles.count, "o vínculo precisa existir para o teste provar algo"
    assert_not UserPolicy.new(user, user).access_app?
  end

  private

  def connection
    ActiveRecord::Base.connection
  end
end
