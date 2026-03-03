class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    share_link = ShareLink.find_by!(token: params[:token])
    return head :gone if share_link.expires_at <= Time.current

    @room = share_link.room
    @viewer_profile = current_user.profile

    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile

    @memberships = @room.room_memberships
                        .includes(profile: [ :user, :hobbies ])
                        .order(created_at: :asc)

    @jsmind_data = build_jsmind_data(@room, @memberships)
  end

  private

  def build_jsmind_data(room, memberships)
    hobby_to_profiles = {}
    memberships.each do |membership|
      membership.profile.hobbies.sort_by(&:name).each do |hobby|
        (hobby_to_profiles[hobby] ||= []) << membership.profile
      end
    end

    hobby_nodes = hobby_to_profiles.sort_by { |hobby, _| hobby.name }.map do |hobby, profiles|
      profile_nodes = profiles.sort_by(&:id).map do |profile|
        {
          id: "p_#{profile.id}_h_#{hobby.id}",
          topic: profile.user.nickname.presence || "no-name",
          data: { url: room_member_path(room_id: room.id, id: profile.id) }
        }
      end
      { id: "hobby_#{hobby.id}", topic: hobby.name, children: profile_nodes }
    end

    {
      meta: { name: "room-map", version: "0.2" },
      format: "node_tree",
      data: {
        id: "root",
        isroot: true,
        topic: room.label.presence || "この部屋の趣味",
        children: hobby_nodes
      }
    }
  end
end
