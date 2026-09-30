# Criação e renomeação de rubricas.
#
# A criação não é um `create` comum: ela decide de onde vêm os itens, e essa
# regra mora em `Ledgers::Create`. Aqui só se traduz o que veio do formulário.
class LedgersController < ApplicationController
  before_action :set_ledger, only: %i[update destroy reorder]

  def create
    @ledger = Ledgers::Create.call(
      user: current_user,
      name: params.dig(:ledger, :name).to_s,
      copy_from: source
    )

    # A rubrica recém-criada passa a ser a selecionada — quem acabou de criar
    # quer trabalhar nela.
    session[:ledger_id] = @ledger.id

    # Redireciona em vez de responder Turbo Stream: criar rubrica acontece uma
    # vez por período, e a tela inteira muda (picker, resumo, lista). Revalidar
    # via navegação é mais simples e mais correto do que remendar cada pedaço.
    redirect_to root_path(ledger: @ledger.id)
  rescue ActiveRecord::RecordInvalid => e
    @error = e.record.errors.full_messages.to_sentence
    @previous_ledger = previous_ledger
    # Devolve o nome digitado, em vez de um campo em branco.
    @ledger = current_user.ledgers.new(name: params.dig(:ledger, :name))

    respond_to do |format|
      # O erro volta para dentro do modal, sem fechar nem perder o que foi dito.
      format.turbo_stream { render :error, status: :unprocessable_entity }
      format.html { redirect_to root_path, alert: @error }
    end
  end

  def update
    @ledger.update!(name: params.dig(:ledger, :name).to_s)

    redirect_to root_path(ledger: @ledger.id)
  rescue ActiveRecord::RecordInvalid => e
    # Nome em branco: avisa em vez de derrubar com 500.
    redirect_to root_path(ledger: @ledger.id), alert: e.record.errors.full_messages.to_sentence
  end

  # Leva as despesas da rubrica junto (`dependent: :destroy` no model: o item
  # não tem significado fora da rubrica). Por isso a tela confirma antes,
  # dizendo QUANTAS vão — a consequência não é óbvia pelo nome da ação.
  def destroy
    @ledger.destroy

    # A rubrica excluída não pode continuar sendo a selecionada na sessão.
    session[:ledger_id] = current_user.ledgers.recent_first.first&.id

    redirect_to root_path, notice: t("ledgers.flash.destroyed")
  end

  # Reordenação das despesas da rubrica.
  #
  # Não devolve corpo: o cliente já aplicou a ordem na tela antes de enviar, e
  # re-renderizar a lista faria a linha pular de volta sob o dedo se a resposta
  # chegasse fora de tempo.
  def reorder
    Ledgers::Reorder.call(ledger: @ledger, ids: params[:ids])

    head :no_content
  end

  private

  # A caixa "Copiar as despesas de …" vem marcada; desmarcada significa rubrica
  # vazia. `Ledgers::Create` recebe `:previous` (copia a anterior, ou semeia com
  # as despesas se for a primeira) ou `nil` (nasce vazia).
  def source
    ActiveModel::Type::Boolean.new.cast(params[:copy_previous]) ? Ledgers::Create::PREVIOUS : nil
  end

  # Rubrica usada para sugerir o nome e oferecer a cópia: a mais recente.
  def previous_ledger
    current_user.ledgers.recent_first.first
  end

  def set_ledger
    @ledger = current_user.ledgers.find(params[:id])
  end
end
