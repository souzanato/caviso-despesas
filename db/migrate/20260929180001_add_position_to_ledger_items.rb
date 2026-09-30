class AddPositionToLedgerItems < ActiveRecord::Migration[8.1]
  def up
    add_column :ledger_items, :position, :integer

    # Preenche pela ordem que a lista JÁ tinha (id crescente), para que a
    # migration não mude nada visualmente: no dia em que ela roda, o usuário
    # vê exatamente a mesma lista.
    execute <<~SQL
      UPDATE ledger_items
      SET position = ordered.rn
      FROM (
        SELECT id, row_number() OVER (PARTITION BY ledger_id ORDER BY id) AS rn
        FROM ledger_items
      ) AS ordered
      WHERE ledger_items.id = ordered.id
    SQL

    change_column_null :ledger_items, :position, false

    # Índice NÃO único de propósito.
    #
    # Reordenar troca posições entre linhas na mesma transação, e um índice
    # único seria violado no meio do caminho — o Postgres verifica a cada
    # statement. Empates não acontecem na prática, e o desempate por `id` na
    # ordenação mantém o resultado determinístico se acontecerem.
    add_index :ledger_items, [ :ledger_id, :position ]
  end

  def down
    remove_index :ledger_items, [ :ledger_id, :position ]
    remove_column :ledger_items, :position
  end
end
