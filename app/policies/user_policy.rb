# Quem pode usar o app.
#
# É policy do `User` (e não um `AppPolicy`) porque a pergunta é sobre o ator,
# não sobre um registro: "esta pessoa pode entrar?". Quando aparecerem outras
# capacidades ("pode gerenciar categorias?"), elas entram aqui — e é este o
# lugar onde alguém vai procurá-las.
#
# Sem `ApplicationPolicy` por enquanto: uma policy só não justifica uma classe
# base, e o projeto não tem `BaseController` nem concerns. A base entra quando
# houver a segunda.
class UserPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # O gate do app inteiro. `has_role?` do rolify procura o perfil GLOBAL
  # (resource_type e resource_id nulos), que é exatamente como `add_role`
  # grava — não há risco de casar um perfil preso a outro registro.
  def access_app?
    user.present? && user.has_role?(Profiles::ADMIN)
  end
end
