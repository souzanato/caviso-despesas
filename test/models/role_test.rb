require "test_helper"

# O vínculo usuário↔perfil, e o ponto onde a lista fechada de `Profiles` vira
# regra de verdade.
class RoleTest < ActiveSupport::TestCase
  test "nome fora do vocabulário é inválido" do
    assert Role.new(name: "financeiro").invalid?
    assert Role.new(name: "admin").valid?
  end

  test "nome é obrigatório" do
    assert Role.new(name: nil).invalid?
  end

  test "add_role de perfil conhecido grava um perfil GLOBAL" do
    user = users(:renato)

    user.add_role(Profiles::ADMIN)

    role = user.reload.roles.sole
    assert_equal "admin", role.name
    # Global = sem dono. É o que `has_role?(:admin)` procura, e é o que o gate
    # do app usa — um perfil preso a outro registro não serviria.
    assert_nil role.resource_type
    assert_nil role.resource_id
  end

  test "add_role de perfil desconhecido levanta, e não grava nada" do
    user = users(:renato)

    assert_raises(ActiveRecord::RecordInvalid) { user.add_role(:financeiro) }

    assert_nil Role.find_by(name: "financeiro")
    assert_not user.reload.has_role?(:financeiro)
  end

  test "grant de perfil desconhecido também é barrado" do
    # `grant` é um alias de `add_role` capturado na CARGA do módulo do rolify,
    # não uma delegação em tempo de chamada. Um wrapper que sobrescrevesse só
    # `add_role` deixaria `grant` passar batido — este teste existe para que
    # essa diferença não vire uma porta dos fundos.
    assert_raises(ActiveRecord::RecordInvalid) { users(:renato).grant(:financeiro) }
  end

  test "o mesmo perfil não é concedido duas vezes" do
    user = users(:renato)

    user.add_role(Profiles::ADMIN)
    user.add_role(Profiles::ADMIN)

    assert_equal 1, user.reload.roles.count
    assert_equal 1, Role.where(name: "admin").count
  end

  test "perder o perfil apaga a linha do Role, e é por isso que a lista não mora na tabela" do
    user = users(:renato)
    user.add_role(Profiles::ADMIN)

    user.remove_role(Profiles::ADMIN)

    # Confirmado: `remove_role_if_empty` (padrão do rolify) destrói a linha
    # quando o último portador sai. Um `Role.find_by(name: "admin")` usado como
    # "quais perfis existem" devolveria nil — o catálogo é `Profiles`.
    assert_equal 0, Role.where(name: "admin").count
    assert_not user.reload.has_role?(Profiles::ADMIN)
  end
end
