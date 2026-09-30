# Ver Users::SessionsController para o motivo do override.
#
# OBS: o módulo :confirmable não está habilitado no model User, então o Devise
# não gera as rotas deste controller. Ele existe para o dia em que :confirmable
# for ligado — aí basta acrescentar :confirmable ao User.
class Users::ConfirmationsController < Devise::ConfirmationsController
  layout "devise"
end
