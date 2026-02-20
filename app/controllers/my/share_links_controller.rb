class My::ShareLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: %i[edit update]

  def index
    profile = current_user.profile
    @rooms = profile ? profile.issued_rooms.includes(:share_link) : Room.none
  end

  def edit
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
    @room.update!(room_params)
    redirect_to my_share_links_path, notice: "部屋名を更新しました"
  end

  private

  def set_room
    # 発行者だけが編集できるように絞る
    @room = current_user.profile.issued_rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:label)
  end
end
