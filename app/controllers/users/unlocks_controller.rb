# Ver Users::SessionsController para o motivo do override.
#
# OBS: o módulo :lockable não está habilitado no model User, então o Devise não
# gera as rotas deste controller. Ele existe para o dia em que :lockable for
# ligado — aí basta acrescentar :lockable ao User.
class Users::UnlocksController < Devise::UnlocksController
  layout "devise"
end
