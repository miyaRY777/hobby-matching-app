class SharesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_profile!
  rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

  def show
    share_link      = ShareLink.includes(:room).find_by!(token: params[:token])
    @room           = share_link.room
    @viewer_profile = current_user.profile

    authorize! share_link, to: :show?

    unless allowed_to?(:join?, share_link)
      flash.now[:alert] = "この部屋は現在ロック中のため参加できません"
      @memberships = memberships_for_display
      @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
      return render :show
    end

    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile
    @memberships = memberships_for_display
    @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
  end

  private

  def memberships_for_display
    @room.room_memberships
         .includes(profile: [ :user, { profile_hobbies: { hobby: :hobby_parent_tags } } ])
         .order(created_at: :asc)
  end

  def handle_unauthorized
    head :gone
  end

  def require_profile!
    return if current_user.profile

    redirect_to new_my_profile_path, alert: "部屋に入るにはプロフィールを作成してください"
  end
end
