class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    result = SocialAuthService.call(request.env["omniauth.auth"])

    if result.success?
      sign_in_and_redirect result.user, event: :authentication
    else
      redirect_to new_user_session_path, alert: result.error_message
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "認証に失敗しました"
  end
end
