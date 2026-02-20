class My::ShareLinksController < ApplicationController
  before_action :authenticate_user!

  def index
    profile = current_user.profile
    @rooms = profile ? profile.issued_rooms.includes(:share_link) : Room.none
  end

  # あとで、Service Objectに切り出す
  def create
    issuer_profile = current_user.profile

    Room.transaction do
      room = Room.create!(
        issuer_profile: issuer_profile,
        label: params.dig(:room, :label)
      )

      RoomMembership.create!(room: room, profile: issuer_profile)
      ShareLink.create!(room: room)
    end

    redirect_to my_share_links_path
  end

  def update
  end
end
