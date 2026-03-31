class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def index
    @profiles = ProfileSearchQuery.call(q: params[:q], mode: params[:mode])

    if turbo_frame_request?
      render partial: "profiles/profile_list", locals: { profiles: @profiles }
    end
  end

  def show
    @profile = Profile.includes(profile_hobbies: { hobby: :parent_tag }, user: { avatar_attachment: :blob }).find_by(id: params[:id])
    return redirect_to profiles_path, alert: "プロフィールが見つかりません" unless @profile

    @profile_hobby_map = @profile.profile_hobbies.index_by(&:hobby_id)

    my_profile = current_user.profile
    @shared_hobbies = my_profile ? my_profile.shared_hobbies_with(@profile) : []
  end
end
