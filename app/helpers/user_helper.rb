# Iniciais do usuário para o avatar da topbar.
#
# Ainda não existe imagem de avatar no model (nenhum anexo do Active Storage),
# então as iniciais são sempre o que aparece. Quando houver avatar, troque o
# conteúdo de layouts/_user_menu por um <img> e mantenha isto como fallback.
module UserHelper
  def user_initials(user)
    source = user&.full_name.presence || user&.username.presence || user&.email.to_s
    words = source.to_s.scan(/[[:alnum:]]+/)

    return "?" if words.empty?
    return words.first[0, 2].upcase if words.size == 1

    "#{words.first[0]}#{words.last[0]}".upcase
  end
end
