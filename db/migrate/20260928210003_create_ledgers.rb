class CreateLedgers < ActiveRecord::Migration[8.1]
  def change
    create_table :ledgers do |t|
      t.references :user, null: false, foreign_key: true

      # Sem mês, ano ou período: a rubrica é um agrupador LIVRE. "Janeiro 2026"
      # e "Viagem" são igualmente válidos e o banco não sabe a diferença.
      t.string :name, null: false

      t.timestamps
    end

    # Sustenta a regra de "rubrica anterior": a mais recentemente criada do
    # usuário, ordenada por created_at com id como desempate.
    add_index :ledgers, [ :user_id, :created_at ]
  end
end
