require "test_helper"

# O vocabulário de perfis do app.
#
# A lista é fechada em CÓDIGO (ver o comentário em app/models/profiles.rb para
# por que ela não mora na tabela `roles`). Estes testes prendem o que a mantém
# coerente — sobretudo a relação entre `ALL` e `NAMES`, que é onde um erro
# passaria despercebido e derrubaria a validação do `Role` inteira.
class ProfilesTest < ActiveSupport::TestCase
  test "a lista é fechada e imutável" do
    assert_equal [ :admin ], Profiles::ALL
    assert Profiles::ALL.frozen?, "ALL precisa ser congelada — um push aqui muda o vocabulário em runtime"
    assert Profiles::NAMES.frozen?, "NAMES precisa ser congelada"
  end

  test "NAMES é a forma String de ALL" do
    # Não é redundante com o teste acima: é o que falha no dia em que alguém
    # declarar NAMES à mão e as duas listas divergirem. A validação do `Role`
    # compara contra NAMES, então uma divergência aqui faria o rolify rejeitar
    # TODO perfil — inclusive o :admin legítimo.
    assert_equal Profiles::ALL.map(&:to_s), Profiles::NAMES
  end

  test "known? aceita Symbol e String, e recusa o resto" do
    assert Profiles.known?(:admin)
    assert Profiles.known?("admin")

    assert_not Profiles.known?(:financeiro)
    assert_not Profiles.known?("financeiro")
    assert_not Profiles.known?(nil)
    assert_not Profiles.known?("")
  end
end
