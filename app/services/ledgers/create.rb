# Cria uma rubrica e decide quais itens ela já nasce tendo.
#
# A lógica vive aqui, e não no model nem no controller, porque "criar rubrica"
# é uma operação de domínio com uma regra própria (de onde vêm os itens) que não
# pertence nem à definição de Ledger nem ao transporte HTTP.
#
#   Ledgers::Create.call(user: usuario, name: "Fevereiro 2026")
#   # => copia os itens da rubrica anterior mais recente
#
#   Ledgers::Create.call(user: usuario, name: "Viagem", copy_from: nil)
#   # => nasce vazia
#
#   Ledgers::Create.call(user: usuario, name: "Casa nova", copy_from: outra)
#   # => copia os itens daquela rubrica específica
module Ledgers
  class Create
    # Sentinela para "copie da rubrica anterior", distinta de `nil`, que
    # significa "não copie nada". Usar o mesmo valor para as duas coisas tiraria
    # a possibilidade de criar uma rubrica vazia.
    PREVIOUS = :previous

    def self.call(user:, name:, copy_from: PREVIOUS)
      new(user:, name:, copy_from:).call
    end

    def initialize(user:, name:, copy_from: PREVIOUS)
      @user = user
      @name = name
      @copy_from = copy_from
    end

    def call
      validate_source!

      # Atômico: se a cópia falhar no meio, a rubrica não fica pela metade.
      Ledger.transaction do
        ledger = user.ledgers.create!(name:)
        populate(ledger)
        ledger
      end
    end

    private

    attr_reader :user, :name, :copy_from

    def populate(ledger)
      case copy_from
      when nil      then ledger # nasce vazia, por escolha explícita
      when PREVIOUS then copy_previous_or_seed(ledger)
      else               copy_items(from: copy_from, to: ledger)
      end
    end

    # Sem rubrica anterior não há o que copiar — e isso não é erro.
    #
    # O fallback é semear com as despesas ativas do usuário: a primeira rubrica
    # já nasce com o que ele costuma pagar, em vez de obrigá-lo a montar tudo à
    # mão. Da segunda em diante o comportamento é sempre a cópia.
    def copy_previous_or_seed(ledger)
      previous = previous_ledger(ledger)
      return seed_from_expenses(ledger) if previous.nil?

      copy_items(from: previous, to: ledger)
    end

    # "A rubrica anterior" = a mais recentemente criada do usuário, excluindo a
    # que acabou de nascer.
    #
    # O desempate por `id` não é decorativo: duas rubricas criadas no mesmo
    # segundo empatariam em created_at e o resultado passaria a depender do
    # plano de execução do banco. Com o desempate, a ordem é sempre a mesma.
    def previous_ledger(ledger)
      user.ledgers
          .where.not(id: ledger.id)
          .order(created_at: :desc, id: :desc)
          .first
    end

    def copy_items(from:, to:)
      from.ledger_items.find_each do |item|
        LedgerItem.build_copy(item, ledger: to).save!
      end
    end

    # Todas as despesas do usuário entram — não há filtro de "ativa", porque não
    # existe estado de despesa. O que existe é a despesa.
    def seed_from_expenses(ledger)
      user.expenses.includes(:category).find_each do |expense|
        LedgerItem.build_from(ledger:, expense:).save!
      end
    end

    # Valida a origem ANTES de criar qualquer coisa, para que uma chamada
    # inválida não deixe rubrica pela metade nem gastem uma transação.
    #
    # Os dois motivos de recusa são diferentes e vale distinguir na mensagem:
    # tipo errado é erro de programação; rubrica de outro usuário é tentativa de
    # vazamento entre contas.
    def validate_source!
      return if copy_from.nil? || copy_from == PREVIOUS
      raise ArgumentError, "copy_from inválido: #{copy_from.inspect}" unless copy_from.is_a?(Ledger)
      return if copy_from.user_id == user.id

      raise ArgumentError, "copy_from pertence a outro usuário"
    end
  end
end
