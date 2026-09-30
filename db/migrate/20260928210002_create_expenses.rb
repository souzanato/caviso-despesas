class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.string :name, null: false
      # precision/scale explícitos: dinheiro não passa por float em nenhum
      # ponto. 12,2 cobre até 9.999.999.999,99.
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Mesma regra da validação Ruby, reforçada no banco.
    add_check_constraint :expenses, "amount >= 0", name: "expenses_amount_non_negative"

    # A listagem natural da área autenticada é "minhas despesas ativas".
    add_index :expenses, [ :user_id, :active ]
  end
end
