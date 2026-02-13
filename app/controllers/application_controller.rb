class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  # 追加：戻り先を保存
  before_action :store_user_location!, if: :storable_location?

  protected

  def after_sign_up_path_for(resource)
    root_path
  end

  # 修正：保存したlocationがあればそこへ。なければprofilesへ
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || profiles_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname])
  end

  private

  def storable_location?
    request.get? &&
      is_navigational_format? &&
      !devise_controller? &&
      !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
