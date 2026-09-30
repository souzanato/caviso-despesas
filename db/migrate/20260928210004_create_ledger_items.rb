class CreateLedgerItems < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_items do |t|
      t.references :ledger, null: false, foreign_key: true
      t.references :expense, null: false, foreign_key: true

      # Snapshots: o estado da despesa no momento em que ela entrou na rubrica.
      # Sem eles, mudar o cadastro permanente reescreveria o passado.
      t.string :name_snapshot, null: false
      t.string :category_name_snapshot, null: false

      t.decimal :amount, precision: 12, scale: 2, null: false
      t.boolean :paid, null: false, default: false

      t.timestamps
    end

    add_check_constraint :ledger_items, "amount >= 0", name: "ledger_items_amount_non_negative"

    # "Quanto já paguei nesta rubrica" é a consulta mais frequente do domínio.
    add_index :ledger_items, [ :ledger_id, :paid ]

    # A FK para expenses é o que impede, no banco, apagar uma despesa que já
    # sustentou rubricas — a validação Ruby sozinha seria contornável.
  end
end
