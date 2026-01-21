class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # devise 追加
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # 新規登録後のリダイレクト先
  def after_sign_up_path_for(resource)
    root_path
  end

  # ログイン後も同じ場所に飛ばしたい場合（任意）
  def after_sign_in_path_for(resource)
    profiles_path
  end

  def configure_permitted_parameters
    # 新規登録時
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :nickname ])
  end
end
