# Título e subtítulo das telas de autenticação, resolvidos pelo layout
# dedicado (app/views/layouts/devise.html.erb) a partir do controller/ação
# atual. Assim as views de app/views/devise não precisam declarar nada.
module AuthHelper
  # Quando há erro de validação, o Devise renderiza :new a partir do #create e
  # :edit a partir do #update — mas action_name continua "create"/"update".
  # Sem esse mapa, a tela perderia o título exatamente quando o usuário mais
  # precisa dela.
  ACTION_ALIASES = { "create" => "new", "update" => "edit" }.freeze

  def auth_screen_key
    action = ACTION_ALIASES.fetch(action_name, action_name)
    "#{controller_name}_#{action}"
  end

  def auth_screen_title
    t("auth.screens.#{auth_screen_key}.title", default: nil)
  end

  def auth_screen_subtitle
    t("auth.screens.#{auth_screen_key}.subtitle", default: nil)
  end
end
