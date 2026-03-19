class Mypage::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    if current_user.update(user_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to mypage_root_path, notice: "ニックネームを更新しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("nickname",
            partial: "mypage/dashboards/nickname_form"),
            status: :unprocessable_entity
        end
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:nickname)
  end
end
