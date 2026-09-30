class RemoveActiveFromExpenses < ActiveRecord::Migration[8.1]
  def change
    # A despesa NÃO TEM ESTADO. Ela existe — e tem nome, valor e categoria.
    # Nada mais.
    #
    # Não há arquivamento porque não há o que arquivar: para tirar uma despesa
    # de circulação, ela é excluída. E a exclusão é bloqueada pelo domínio
    # quando a despesa já sustenta alguma rubrica, o que preserva o histórico
    # sem precisar de um booleano intermediário.
    remove_index :expenses, [ :user_id, :active ]
    remove_column :expenses, :active, :boolean
  end
end
