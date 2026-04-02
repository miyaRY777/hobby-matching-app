class Admin::DashboardsController < Admin::BaseController
  def show
    @current_admin_name = current_user.nickname
  end
end
