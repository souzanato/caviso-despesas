class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    # Unicidade por usuário SEM depender de maiúsculas: "Moradia" e "moradia"
    # são a mesma categoria. É um índice funcional porque a validação Ruby
    # sozinha não sobrevive a duas requisições concorrentes criando a mesma
    # categoria — o banco é quem garante.
    add_index :categories, "user_id, lower(name)",
              unique: true,
              name: "index_categories_on_user_id_and_lower_name"
  end
end
