# Sobrescreve o controller do Devise apenas para aplicar o layout dedicado
# das telas de autenticação. Também é o ponto de extensão para customizações
# futuras (ex.: passkey/WebAuthn) sem mexer no gem.
class Users::SessionsController < Devise::SessionsController
  layout "devise"
end
