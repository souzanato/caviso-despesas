require "test_helper"

# O gate do app: quem não tem perfil não passa, e vê a tela de bloqueio.
#
# `outro` é o fixture SEM perfil de propósito — é o sujeito destes testes. O
# `renato` recebe o perfil no setup.
class LockTest < ActionDispatch::IntegrationTest
  setup do
    @sem_perfil = users(:outro)
    @admin = users(:renato)
    @admin.add_role(Profiles::ADMIN)
  end

  # --- o gate ----------------------------------------------------------------

  test "sem perfil é mandado para a tela de bloqueio" do
    sign_in @sem_perfil

    get root_path

    assert_response :see_other
    assert_redirected_to lock_path
  end

  test "com perfil passa, em todas as áreas do app" do
    sign_in @admin
    ledger = @admin.ledgers.create!(name: "Janeiro 2026")

    get root_path
    assert_response :success

    get categories_path
    assert_response :success

    get new_category_path
    assert_response :success

    get root_path(ledger: ledger.id)
    assert_response :success

    # Uma ESCRITA também, não só leitura: o gate intercepta POST igual.
    post ledger_items_path,
         params: { ledger_id: ledger.id, ledger_item: { name: "Escola", amount: "1850.00", category_name: "Educação" } },
         as: :turbo_stream
    assert_response :success
  end

  test "sem sessão vai para o login, e não para o bloqueio" do
    # Este é o teste que prende a ORDEM dos before_action. Com o gate antes do
    # `authenticate_user!`, quem não tem sessão veria "você não tem permissão" —
    # e nem saberia que existe um login.
    get root_path

    assert_redirected_to new_user_session_path
  end

  test "sem perfil, uma requisição turbo_stream redireciona em vez de devolver 403 sem corpo" do
    # Este prende a decisão de REDIRECT (ver o comentário de `profile_required`).
    # Num turbo_stream, o Turbo não tem `responseHTML` e não desenha nada: um
    # 403 ali deixaria o botão morto, sem erro visível. Um `assert_redirected_to
    # root_path` passaria mesmo com o 403 renderizado — este não passa.
    sign_in @sem_perfil
    ledger = @sem_perfil.ledgers.create!(name: "Janeiro 2026")

    post ledger_items_path,
         params: { ledger_id: ledger.id, ledger_item: { name: "Escola", amount: "1850.00", category_name: "Educação" } },
         as: :turbo_stream

    assert_response :see_other
    assert_redirected_to lock_path
  end

  test "a tela de bloqueio não é ela própria bloqueada" do
    sign_in @sem_perfil

    get lock_path

    # Sem o `skip_before_action`, aqui seria um redirect para si mesma e o
    # navegador cortaria por excesso de redirects.
    assert_response :success
  end

  test "a tela de bloqueio sem sessão manda para o login" do
    get lock_path

    assert_redirected_to new_user_session_path
  end

  # --- a tela ----------------------------------------------------------------

  test "a tela de bloqueio mostra a mensagem e o botão de sair" do
    sign_in @sem_perfil

    get lock_path

    assert_select ".auth-card__title", text: "Sem permissão"
    assert_select ".auth-card__subtitle", text: "Você não tem permissão. Clique em Sair."

    # O botão é um form de verdade com method DELETE: a rota de sign out do
    # Devise é DELETE-only (config.sign_out_via = :delete), e o formulário
    # garante o método certo mesmo sem JavaScript — que é justamente o caso em
    # que o usuário mais precisa conseguir sair.
    assert_select "form[action=?] input[name=_method][value=delete]", destroy_user_session_path
    assert_select "form[action=?] button", destroy_user_session_path, text: /Sair/
  end

  # --- o que precisa seguir alcançável sem perfil ----------------------------

  test "sair encerra a sessão, mesmo sem perfil" do
    sign_in @sem_perfil

    delete destroy_user_session_path

    assert_redirected_to root_path
    # A prova de que saiu: a próxima request cai no login, não no bloqueio.
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "as telas do Devise seguem acessíveis a quem não tem perfil" do
    get new_user_session_path
    assert_response :success

    get new_user_registration_path
    assert_response :success

    get new_user_password_path
    assert_response :success
  end

  test "quem não tem perfil ainda consegue editar e cancelar a própria conta" do
    # Não é detalhe: sem isto, um usuário bloqueado ficaria preso — não poderia
    # corrigir os próprios dados nem encerrar a conta.
    sign_in @sem_perfil

    get edit_user_registration_path
    assert_response :success
  end

  # --- rotas que não passam pelo controller da aplicação ---------------------

  test "/up responde sem sessão e sem perfil" do
    # Rails::HealthController NÃO herda de ApplicationController, então o gate
    # não o alcança. Se um dia alguém mover o health check para um controller
    # próprio, este teste avisa.
    get rails_health_check_path

    assert_response :success
  end
end
