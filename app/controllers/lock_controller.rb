# A tela de quem entrou mas não tem perfil.
#
# `skip_before_action :require_profile` é o que impede o loop: sem ele, o gate
# manda para cá e o gate daqui manda para cá de novo, até o navegador cortar
# por excesso de redirects.
#
# `authenticate_user!` continua valendo — é uma tela para quem ESTÁ logado e não
# pode entrar. Sem sessão, o caminho é o login, não esta tela: não faria sentido
# oferecer "Sair" a quem não entrou.
class LockController < ApplicationController
  # Reusa o padrão visual da autenticação (app/views/layouts/devise.html.erb):
  # tema dark, card centralizado, sem shell. O usuário está fora do app, e o
  # visual de fora é o que corresponde a isso.
  #
  # De graça, o layout traz o título e o subtítulo via AuthHelper — a chave é
  # `auth.screens.lock_show.*` (controller_name + action_name).
  layout "devise"

  skip_before_action :require_profile

  def show
  end
end
