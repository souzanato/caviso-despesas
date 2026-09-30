# Ver Users::SessionsController para o motivo do override.
class Users::RegistrationsController < Devise::RegistrationsController
  layout "devise"
end
