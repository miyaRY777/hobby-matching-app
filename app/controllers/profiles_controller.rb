class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def index
    @profiles = Profile.includes(:user, :hobbies).order(created_at: :desc)
  end

  def show
    @profile = Profile.includes(:user, :hobbies).find_by(id: params[:id])
    return redirect_to profiles_path, alert: "プロフィールが見つかりません" unless @profile

    my_hobbies = current_user.profile&.hobbies || []
    @shared_hobbies = my_hobbies & @profile.hobbies
  end
end
