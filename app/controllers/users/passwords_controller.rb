# Ver Users::SessionsController para o motivo do override.
class Users::PasswordsController < Devise::PasswordsController
  layout "devise"
end
