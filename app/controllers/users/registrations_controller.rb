class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(_resource)
    mypage_settings_path
  end
end
