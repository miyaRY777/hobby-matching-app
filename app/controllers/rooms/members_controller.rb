module Rooms
  # 責務: 部屋ページのメンバー詳細。見る権利は RoomPolicy#show?。
  class MembersController < ApplicationController
    include AuthorizesRoomShow
    before_action :authenticate_user!
    before_action :set_room
    before_action :authorize_room!

    def show
      @profile = @room.profiles.includes(:user, profile_hobbies: { hobby: :hobby_parent_tags }).find(params[:id])

      @room_related_phs = @profile.profile_hobbies.select do |ph|
        ph.hobby.hobby_parent_tags.any? { |hpt| hpt.room_type == @room.room_type }
      end
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end
  end
end
