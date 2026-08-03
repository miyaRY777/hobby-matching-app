module Rooms
  class ParentTagMembersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room
    before_action :authorize_member!
    before_action :set_parent_tag

    def index
      profiles = RoomParentTagProfilesQuery.call(room: @room, parent_tag: @parent_tag)
      @profiles = profiles.page(params[:page]).per(1)

      if @profiles.out_of_range? && @profiles.total_pages.positive?
        @profiles = profiles.page(@profiles.total_pages).per(1)
      end

      @profile = @profiles.first
      @room_related_phs = room_related_profile_hobbies(@profile)
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end

    def authorize_member!
      return if current_user.profile &&
                RoomMembership.exists?(room: @room, profile: current_user.profile)

      head :forbidden
    end

    def set_parent_tag
      @parent_tag = ParentTag.find_by!(id: params[:parent_tag_id], room_type: @room.room_type)
    end

    def room_related_profile_hobbies(profile)
      return [] unless profile

      profile.profile_hobbies.select do |profile_hobby|
        profile_hobby.hobby.hobby_parent_tags.any? do |hobby_parent_tag|
          hobby_parent_tag.room_type == @room.room_type
        end
      end
    end
  end
end
