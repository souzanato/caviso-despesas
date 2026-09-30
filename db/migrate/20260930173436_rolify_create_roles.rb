class RolifyCreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table(:roles) do |t|
      # `null: false` porque um perfil sem nome não identifica nada — e é por
      # nome que o rolify pergunta (`has_role?(:admin)`).
      t.string :name, null: false
      t.references :resource, polymorphic: true

      t.timestamps
    end

    create_table(:users_roles, id: false) do |t|
      # `foreign_key` com cascata, e não só `t.references`: em Rails 5+ o
      # `references` cria índice mas NÃO cria FK, então apagar um usuário
      # deixaria o vínculo órfão em `users_roles`. O cancelamento de conta do
      # Devise (DELETE /users) faz exatamente isso, e `test/models/user_test.rb`
      # já exercita. `dependent:` não resolve: o rolify filtra essa opção ao
      # montar a associação, então a FK é a única defesa.
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :role, null: false, foreign_key: { on_delete: :cascade }
    end

    # Not redundant with the unique indexes below: those are partial, so none of
    # them can answer a lookup by name alone.
    add_index(:roles, :name)

    # A role is identified by its name at one of three mutually exclusive
    # levels, so each level gets its own partial unique index:
    #
    #   global     resource_type IS NULL     AND resource_id IS NULL
    #   class      resource_type IS NOT NULL AND resource_id IS NULL
    #   instance                                 resource_id IS NOT NULL
    #
    # One index over all three columns cannot replace these. NULLs compare as
    # distinct in a unique index, so it would let two concurrent creations of
    # the same global or class scoped role both succeed.
    #
    # The predicates are mutually exclusive, so the same role name can still be
    # held at every level at once.
    add_index(:roles, [ :name ],
              unique: true,
              where: "resource_type IS NULL AND resource_id IS NULL",
              name: "index_roles_global")
    add_index(:roles, [ :name, :resource_type ],
              unique: true,
              where: "resource_type IS NOT NULL AND resource_id IS NULL",
              name: "index_roles_class_scoped")
    add_index(:roles, [ :name, :resource_type, :resource_id ],
              unique: true,
              where: "resource_id IS NOT NULL",
              name: "index_roles_instance_scoped")
    add_index(:users_roles, [ :user_id, :role_id ], unique: true)
  end
end
