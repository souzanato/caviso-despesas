# Cadastro PERMANENTE de uma despesa: "Internet", "Prestação escola".
#
# Não guarda estado de pagamento nem valor de período — isso pertence ao
# LedgerItem. Aqui vive só a definição reutilizável.
class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category

  # Sem `dependent: :destroy` de propósito: apagar uma despesa que já sustentou
  # rubricas reescreveria o histórico. Bloqueia e explica.
  #
  # Não existe estado intermediário (arquivada, inativa): a despesa existe ou
  # não existe. Uma despesa em uso é simplesmente indestrutível — o que já
  # protege o histórico sem precisar de um booleano.
  has_many :ledger_items, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true
  validates :amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  # `user_id` é denormalizado em relação à categoria (que também é do usuário).
  # Sem esta checagem, nada impediria montar uma despesa do usuário A apontando
  # para uma categoria do usuário B.
  validate :category_belongs_to_same_user

  private

  def normalize_name
    self.name = name.squish if name.present?
  end

  def category_belongs_to_same_user
    return if category.nil? || user_id.nil?
    return if category.user_id == user_id

    errors.add(:category, :different_user)
  end
end
