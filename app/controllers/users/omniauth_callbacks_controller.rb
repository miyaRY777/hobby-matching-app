class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_oauth
  end

  def discord
    handle_oauth
  end

  def failure
    redirect_to new_user_session_path, alert: "認証に失敗しました"
  end

  private

  def handle_oauth
    result = SocialAuthService.call(request.env["omniauth.auth"])

    if result.success?
      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in_and_redirect result.user, event: :authentication
    else
      redirect_to new_user_session_path, alert: result.error_message
    end
  end
end
