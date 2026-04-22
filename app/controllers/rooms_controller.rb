class RoomsController < ApplicationController
  before_action :authenticate_user!

  def index
    @rooms = Room.unlocked
                 .includes(issuer_profile: :user, room_memberships: { profile: :user })
                 .order(created_at: :desc)

    profile = current_user.profile
    @joined_room_ids = profile&.joined_room_ids || []
    @issued_room_ids = profile&.issued_room_ids || []
  end
end
