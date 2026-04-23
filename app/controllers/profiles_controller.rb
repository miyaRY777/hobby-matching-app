class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def index
    @profiles = ProfileSearchQuery.call(q: params[:q], mode: params[:mode])
               .page(params[:page]).per(8)

    if turbo_frame_request?
      render partial: "profiles/profile_list", locals: { profiles: @profiles }
    end
  end

  def show
    @profile = Profile.includes(
      :hobbies,
      profile_hobbies: { hobby: :hobby_parent_tags },
      user: { avatar_attachment: :blob }
    ).find_by(id: params[:id])
    return redirect_to profiles_path, alert: "プロフィールが見つかりません" unless @profile

    @profile_hobby_map = @profile.profile_hobbies.index_by(&:hobby_id)

    # current_user.profile は includes を付けられないため、直接クエリで hobbies を eager load する
    my_profile = Profile.includes(:hobbies).find_by(user_id: current_user.id)
    @shared_hobbies = my_profile ? my_profile.shared_hobbies_with(@profile) : []
  end
end
