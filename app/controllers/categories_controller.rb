# CRUD de categorias de despesa.
#
# Todo acesso passa por `current_user.categories`, tanto na listagem quanto na
# busca por id. Escopar apenas na criação não bastaria: sem o escopo também no
# `find`, um id de outra conta colado na URL daria acesso à categoria alheia.
class CategoriesController < ApplicationController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = current_user.categories.order(Arel.sql("lower(name)"))
  end

  def new
    @category = current_user.categories.new
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: t("categories.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t("categories.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # A categoria só é apagada se o domínio permitir. Quando há despesas apontando
  # para ela, `restrict_with_error` recusa e explica — o histórico nunca é
  # apagado em cascata (§ Expense).
  def destroy
    if @category.destroy
      redirect_to categories_path, notice: t("categories.flash.destroyed")
    else
      redirect_to categories_path, alert: t("categories.flash.in_use")
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
