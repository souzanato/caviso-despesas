class GrantInitialAdminProfile < ActiveRecord::Migration[8.1]
  # Bootstrap: sem isto, um app que já tem usuários fica inacessível para todo
  # mundo. O gate exige um perfil que ninguém possui e não há tela para
  # concedê-lo — a única saída seria o console.
  #
  # Concede `admin` ao usuário mais antigo, UMA vez:
  #
  # - Idempotente e auto-desativável: se QUALQUER usuário já tem o perfil, não
  #   faz nada. Rodar isto num app que já tem admins não concede nada a ninguém.
  # - Não roda em teste: o banco de teste é carregado de db/schema.rb, não de
  #   migrações. A suíte continua exercitando "usuário sem perfil", que é o caso
  #   que importa cobrir.
  # - SQL cru de propósito: a migração não pode depender dos models `User` e
  #   `Role`, que vão mudar com o tempo e deixariam esta migração quebrada.
  #
  # NÃO faz o contrário (abrir o gate quando não existe admin): isso
  # transformaria "alguém removeu o último admin" em "o app reabriu para todo
  # mundo", que é pior que o bloqueio.
  def up
    return if admin_exists?

    user_id = select_value("SELECT id FROM users ORDER BY id LIMIT 1")
    return if user_id.nil?

    role_id = select_value(<<~SQL)
      SELECT id FROM roles
      WHERE name = 'admin' AND resource_type IS NULL AND resource_id IS NULL
      LIMIT 1
    SQL
    role_id ||= select_value(<<~SQL)
      INSERT INTO roles (name, created_at, updated_at)
      VALUES ('admin', now(), now())
      RETURNING id
    SQL

    execute(<<~SQL)
      INSERT INTO users_roles (user_id, role_id)
      VALUES (#{user_id.to_i}, #{role_id.to_i})
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    # Sem volta automática: tirar o perfil do primeiro usuário é decisão de
    # operação, não rollback de schema. Use `rails roles:revoke[username,admin]`.
  end

  private

  def admin_exists?
    select_value(<<~SQL).present?
      SELECT 1 FROM users_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE r.name = 'admin' AND r.resource_type IS NULL AND r.resource_id IS NULL
      LIMIT 1
    SQL
  end
end
