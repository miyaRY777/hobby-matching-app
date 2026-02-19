class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    share_link = ShareLink.find_by!(token: params[:token])
    return head :gone if share_link.expires_at <= Time.current

    @room = share_link.room
    viewer_profile = current_user.profile

    RoomMembership.find_or_create_by!(room: @room, profile: viewer_profile) if viewer_profile

  @memberships = @room.room_memberships
                      .includes(profile: :user)
                      .order(created_at: :asc)
  end
end
