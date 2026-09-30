class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout "devise"

  # `authenticate_user!` gerado pelo Devise já se ignora em controllers do
  # Devise (usa `if !devise_controller?`), mas mantemos por segurança caso o
  # callback passe a ser servido fora da árvore do DeviseController.
  skip_before_action :authenticate_user!, raise: false

  def google_oauth2
    auth = request.env["omniauth.auth"]

    # A rota de callback também existe no router; se a requisição chegar aqui
    # sem passar pela middleware do OmniAuth, `omniauth.auth` vem nil.
    if auth.blank?
      return redirect_to new_user_session_path, alert: I18n.t("omniauth.google.missing_auth")
    end

    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      session["devise.google_data"] = auth.except(:extra)
      redirect_to new_user_registration_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def failure
    redirect_to new_user_session_path, alert: I18n.t("omniauth.google.failure")
  end
end
