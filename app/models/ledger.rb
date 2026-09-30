# Rubrica: agrupador LIVRE de despesas.
#
# Não existe campo de mês, ano ou período. "Janeiro 2026", "Viagem", "Casa nova"
# e "Antes das férias" são todos o mesmo tipo de coisa para o domínio — quem dá
# sentido ao recorte é o usuário, pelo nome.
#
# Uma mudança estrutural importante: mudar o cadastro de uma despesa hoje não
# altera nenhuma rubrica já criada, porque cada item guarda seu próprio snapshot.
class Ledger < ApplicationRecord
  belongs_to :user

  # Aqui `dependent: :destroy` é correto — e é o único lugar onde é.
  # LedgerItem é parte do agregado da rubrica: não tem significado sozinho.
  # Apagar uma rubrica é apagar o grupo inteiro de propósito, não perder
  # histórico por efeito colateral.
  # Ordenado pela posição: a ordem das despesas é do usuário, não do banco.
  has_many :ledger_items, -> { ordered }, dependent: :destroy

  validates :name, presence: true

  # "Recentes primeiro" precisa ser determinístico: created_at sozinho empata
  # quando duas rubricas nascem no mesmo segundo (comum em teste e em script).
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # Totais derivados. Nada disso é coluna: seriam valores que podem divergir do
  # que realmente está gravado nos itens.
  #
  # `.to_d` normaliza o retorno: `sum` sobre relação vazia devolve Integer 0, e
  # misturar Integer com BigDecimal no mesmo método é uma armadilha silenciosa.
  def total_amount
    ledger_items.sum(:amount).to_d
  end

  def paid_amount
    ledger_items.where(paid: true).sum(:amount).to_d
  end

  def remaining_amount
    total_amount - paid_amount
  end
end
