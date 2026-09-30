# Menu lateral da aplicação. Fonte única da verdade: a view só itera e o
# parcial layouts/_nav_item decide como renderizar.
#
# Regras:
# - no máximo 2 níveis (item de primeiro nível -> submenu);
# - só o primeiro nível tem ícone;
# - `path` ausente significa "a rota ainda não existe": o item é renderizado
#   como texto inerte em vez de link quebrado. Para ativar, basta apontar o
#   path para o helper de rota (ex.: `path: :expenses_path`) — nada mais muda.
module NavigationHelper
  NAVIGATION = [
    {
      label: "app.nav.registry.label",
      icon: "bi-folder2-open",
      children: [
        { label: "app.nav.registry.categories", path: :categories_path }
      ]
    }
  ].freeze

  def navigation_items
    NAVIGATION
  end

  # Aceita um Symbol (nome do helper de rota) ou uma String já resolvida.
  # Devolve nil quando o destino ainda não existe.
  def navigation_path(item)
    path = item[:path]
    return nil if path.blank?

    path.is_a?(Symbol) ? public_send(path) : path
  end

  def navigation_active?(item)
    path = navigation_path(item)
    path.present? && current_page?(path)
  end
end
