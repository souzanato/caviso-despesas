# A tela inicial É o app: rubricas à esquerda, despesas da rubrica selecionada
# à direita. Não há dashboard separado.
class HomeController < ApplicationController
  DEFAULT_SORT = "manual"

  def index
    @ledgers = current_user.ledgers.recent_first
    @ledger = selected_ledger
    @sort = selected_sort
    # `reorder`, e não `order`: a associação já traz a ordem manual como escopo
    # padrão, e `order` compõe com ela em vez de substituí-la.
    @ledger_items = @ledger ? @ledger.ledger_items.reorder(LedgerItem::ORDERS[@sort]).includes(:expense) : []
  end

  private

  # A URL manda, e a sessão lembra — mesmo padrão da rubrica selecionada, para
  # que recarregar ou compartilhar o link preserve o que se está vendo.
  def selected_sort
    candidato = params[:sort].presence || session[:ledger_sort].presence || DEFAULT_SORT
    candidato = DEFAULT_SORT unless LedgerItem::ORDERS.key?(candidato)

    session[:ledger_sort] = candidato
  end

  # A rubrica selecionada é resolvida nesta ordem:
  #   1. o que veio na URL  — recarregar ou compartilhar o link mantém a seleção
  #   2. a última aberta    — continuidade entre visitas
  #   3. a mais recente     — primeira visita
  #
  # Tudo por `current_user.ledgers`, então um id de outra conta na URL cai no
  # passo 2 em vez de vazar a rubrica alheia.
  def selected_ledger
    scope = current_user.ledgers
    ledger = scope.find_by(id: params[:ledger]) ||
             scope.find_by(id: session[:ledger_id]) ||
             scope.recent_first.first

    session[:ledger_id] = ledger&.id
    ledger
  end
end
