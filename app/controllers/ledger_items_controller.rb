# Criação e marcação de pagamento de uma despesa dentro de uma rubrica.
#
# `paid` pertence ao item, não à despesa: a mesma despesa pode estar paga em
# Janeiro e pendente em Fevereiro sem conflito.
class LedgerItemsController < ApplicationController
  before_action :set_ledger_item, only: %i[update destroy details]

  def create
    @ledger = current_user.ledgers.find(params[:ledger_id])

    # Categoria é obrigatória. Sem ela, levantamos como erro de VALIDAÇÃO para
    # reaproveitar o mesmo caminho de falha — que devolve o formulário aberto
    # com a mensagem, em vez de derrubar com 500.
    if category.nil?
      @ledger_item = @ledger.ledger_items.build(
        name_snapshot: params.dig(:ledger_item, :name),
        amount: params.dig(:ledger_item, :amount)
      )
      @ledger_item.errors.add(:category_name_snapshot, :blank)
      raise ActiveRecord::RecordInvalid, @ledger_item
    end

    LedgerItems::Add.call(
      ledger: @ledger,
      name: params.dig(:ledger_item, :name).to_s,
      amount: params.dig(:ledger_item, :amount).to_s,
      category: category
    )

    refresh_list

    respond_to do |format|
      # Fecha o modal e atualiza só o que mudou — a lista e o resumo — em vez de
      # recarregar a tela inteira.
      format.turbo_stream
      format.html { redirect_to root_path(ledger: @ledger.id) }
    end
  rescue ActiveRecord::RecordInvalid => e
    # O que o usuário digitou volta para o formulário. Perder o preenchimento
    # por causa de um nome em branco seria punir por um erro trivial.
    @ledger_item = @ledger.ledger_items.build(amount: params.dig(:ledger_item, :amount))
    @name_value = params.dig(:ledger_item, :name)
    @error = e.record.errors.full_messages.to_sentence

    respond_to do |format|
      # A falha volta para dentro do próprio modal, sem fechá-lo nem perder o
      # que o usuário digitou.
      format.turbo_stream { render :error, status: :unprocessable_entity }
      format.html { redirect_to root_path(ledger: @ledger.id), alert: @error }
    end
  end

  def update
    @ledger_item.update!(paid: paid?)

    respond_to do |format|
      # Turbo Stream substitui a linha e o resumo em vez de recarregar a tela:
      # marcar pago é a ação mais frequente, e um reload inteiro a tornaria
      # pesada e faria a lista piscar.
      format.turbo_stream
      format.html { redirect_to root_path(ledger: @ledger_item.ledger_id) }
    end
  end

  # Edita o que ESTA rubrica registra da despesa: nome, valor e categoria.
  #
  # Mexe nos snapshots do item, nunca no cadastro da despesa — é o que a
  # especificação chama de "valor próprio daquele período". Editar Fevereiro
  # não encosta em Janeiro, e a despesa compartilhada segue intacta.
  #
  # Responde com redirect, e não Turbo Stream: a linha inteira muda, e a edição
  # não é a ação frequente que justifique remendar o DOM.
  def details
    @ledger_item.update!(
      name_snapshot: params.dig(:ledger_item, :name_snapshot).to_s,
      category_name_snapshot: category.name,
      amount: params.dig(:ledger_item, :amount).to_s
    )

    redirect_to root_path(ledger: @ledger.id)
  rescue ActiveRecord::RecordInvalid => e
    # Valor negativo, por exemplo. Sem isto, a edição derrubava com 500 em vez
    # de dizer o que houve — e nada é gravado, porque `update!` é atômico.
    redirect_to root_path(ledger: @ledger.id), alert: e.record.errors.full_messages.to_sentence
  end

  # Remove a despesa DESTA rubrica. A despesa em si continua no cadastro, e as
  # outras rubricas não são tocadas.
  def destroy
    # O desfazer não tem registro "pendente" no banco: os snapshots viajam no
    # corpo do próprio snackbar e voltam no restore. É o que evita inventar uma
    # coluna de exclusão lógica só para sustentar 8 segundos de arrependimento.
    @undo = {
      ledger_id: @ledger.id,
      expense_id: @ledger_item.expense_id,
      name_snapshot: @ledger_item.name_snapshot,
      category_name_snapshot: @ledger_item.category_name_snapshot,
      amount: @ledger_item.amount.to_s,
      paid: @ledger_item.paid
    }
    @removed_name = @ledger_item.name_snapshot

    @ledger_item.destroy
    refresh_list

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path(ledger: @ledger.id) }
    end
  end

  def restore
    @ledger = current_user.ledgers.find(params[:ledger_id])
    expense = current_user.expenses.find(params[:expense_id])

    LedgerItem.create!(
      ledger: @ledger,
      expense: expense,
      name_snapshot: params[:name_snapshot],
      category_name_snapshot: params[:category_name_snapshot],
      amount: params[:amount],
      paid: ActiveModel::Type::Boolean.new.cast(params[:paid])
    )

    refresh_list

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path(ledger: @ledger.id) }
    end
  end

  private

  # Redesenha a lista no modo de ordenação ATUAL. Com `.ordered` fixo, criar uma
  # despesa devolvia a lista para a ordem manual no meio de uma ordenação por
  # custo — e a linha nova aparecia no lugar errado.
  def refresh_list
    @ledger_items = @ledger.ledger_items.reorder(LedgerItem::ORDERS[ledger_sort]).includes(:expense)
  end

  # A categoria vem por id e é resolvida SEMPRE no escopo do usuário: um id de
  # outra conta não deve virar categoria desta despesa.
  #
  # Aceitar o NOME é o caminho da criação na hora: o combobox manda um nome que
  # ainda não existe, e ele é criado aqui.
  # Resolve a categoria do item. Devolve `nil` quando não há como resolver — o
  # chamador transforma isso em erro de validação, e nunca em exceção.
  def category
    if params.dig(:ledger_item, :category_id).blank? && params.dig(:ledger_item, :category_name).blank?
      # Edição sem mexer na categoria: mantém a que o item já registra.
      #
      # `@ledger_item` só existe em `update`/`details`; em `create` ele é nil, e
      # ler `.category_name_snapshot` aqui derrubava com 500 quando a categoria
      # vinha em branco. Categoria em branco é erro de validação, não exceção.
      return nil if @ledger_item.nil?

      return current_user.categories.find_by("lower(name) = ?", @ledger_item.category_name_snapshot.to_s.downcase) ||
             @ledger_item.expense.category
    end

    if params.dig(:ledger_item, :category_id).present?
      current_user.categories.find(params.dig(:ledger_item, :category_id))
    else
      name = params.dig(:ledger_item, :category_name).to_s.strip.squish
      current_user.categories.find_by("lower(name) = ?", name.downcase) ||
        current_user.categories.create!(name: name)
    end
  end

  def set_ledger_item
    # Escopo pelo usuário na BUSCA: um id de outra conta não deve ser acessível.
    @ledger_item = LedgerItem.joins(:ledger)
                             .where(ledgers: { user_id: current_user.id })
                             .find(params[:id])
    @ledger = @ledger_item.ledger
  end

  def paid?
    ActiveModel::Type::Boolean.new.cast(params.dig(:ledger_item, :paid))
  end
end
