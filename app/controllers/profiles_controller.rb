class ProfilesController < ApplicationController
  def index
    @profiles = Profile.includes(:user, :hobbies).order(created_at: :desc)
  end

  def show
    @profile = Profile.find_by(id: params[:id])
    redirect_to profiles_path, alert: "プロフィールが見つかりません" unless @profile
  end
end
