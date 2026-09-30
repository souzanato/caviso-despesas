# Uma despesa dentro de uma rubrica específica.
#
# É AQUI que mora o estado de pagamento. A mesma despesa pode estar paga em
# Janeiro e pendente em Fevereiro sem nenhum conflito, porque cada rubrica tem
# o seu próprio registro.
#
# `name_snapshot`, `category_name_snapshot` e `amount` são o estado da despesa
# no momento em que ela entrou na rubrica. Nunca são recalculados a partir de
# `Expense` — é isso que impede o passado de mudar quando o cadastro permanente
# é editado.
class LedgerItem < ApplicationRecord
  belongs_to :ledger
  belongs_to :expense

  # A ordem MANUAL, do usuário: a posição é o dado que a guarda. O desempate
  # por `id` mantém o resultado determinístico caso duas linhas empatem.
  scope :ordered, -> { order(:position, :id) }

  # Ordens CALCULADAS. Não tocam em `position` — são um jeito de OLHAR a lista,
  # não uma reordenação. Voltar para "minha ordem" devolve exatamente o que o
  # usuário arrastou.
  #
  # São HASHES porque a associação `Ledger#ledger_items` já traz `ordered` como
  # escopo padrão, e um `order` adicional COMPÕE com ele em vez de substituí-lo:
  # `order(amount: :desc)` sobre a associação gerava
  # `ORDER BY position, id, amount DESC` — ou seja, continuava na ordem manual.
  # O controller aplica estes com `reorder`, que substitui.
  ORDERS = {
    "manual" => { position: :asc, id: :asc },
    "cost" => { amount: :desc, position: :asc, id: :asc },
    "category" => { category_name_snapshot: :asc, name_snapshot: :asc, id: :asc }
  }.freeze

  scope :paid, -> { where(paid: true) }
  scope :pending, -> { where(paid: false) }

  before_create :assign_position

  validates :name_snapshot, presence: true
  validates :category_name_snapshot, presence: true
  validates :amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :paid, inclusion: { in: [ true, false ] }

  private

  # Despesa nova entra no FIM da lista. Quem acabou de lançar sabe onde
  # encontrá-la — no topo ela empurraria tudo e sumiria do lugar esperado.
  def assign_position
    self.position ||= (ledger.ledger_items.maximum(:position) || 0) + 1
  end

  public

  # Tom do chip desta linha. Deriva do SNAPSHOT do nome da categoria, e não do
  # cadastro atual: a rubrica mostra o que era verdade quando a despesa entrou
  # nela, e a cor é parte disso.
  def category_tone
    Category.color_tone_for(category_name_snapshot)
  end

  # Item novo a partir do cadastro permanente: é o caso de criar uma rubrica do
  # zero (a primeira rubrica, ou uma rubrica temática).
  def self.build_from(ledger:, expense:)
    new(
      ledger: ledger,
      expense: expense,
      name_snapshot: expense.name,
      category_name_snapshot: expense.category.name,
      amount: expense.amount,
      paid: false
    )
  end

  # Item novo a partir de OUTRO item: é o caso de copiar uma rubrica.
  #
  # Repare que os snapshots são copiados verbatim, e não relidos de `expense`.
  # Se o cadastro mudou depois que a rubrica de origem nasceu, a cópia preserva
  # o que a origem registrou — copiar é duplicar o registro, não re-observar o
  # cadastro. `paid` sempre nasce falso: pagamento não se herda entre períodos.
  def self.build_copy(item, ledger:)
    new(
      ledger: ledger,
      expense: item.expense,
      name_snapshot: item.name_snapshot,
      category_name_snapshot: item.category_name_snapshot,
      amount: item.amount,
      paid: false
    )
  end
end
