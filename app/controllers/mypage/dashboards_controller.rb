class Mypage::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    return handle_avatar_update if params.dig(:user, :avatar).present?

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

  def handle_avatar_update
    if current_user.update(avatar: params[:user][:avatar])
      redirect_to mypage_root_path, notice: "プロフィール画像を更新しました"
    else
      redirect_to mypage_root_path, alert: current_user.errors[:avatar].join(", ")
    end
  end

  def user_params
    params.require(:user).permit(:nickname, :avatar)
  end
end
