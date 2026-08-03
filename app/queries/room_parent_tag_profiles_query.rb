class RoomParentTagProfilesQuery
  def self.call(room:, parent_tag:)
    Profile
      .joins(:room_memberships, profile_hobbies: { hobby: :hobby_parent_tags })
      .where(room_memberships: { room_id: room.id })
      .where(hobby_parent_tags: { parent_tag_id: parent_tag.id })
      .includes(
        profile_hobbies: { hobby: :hobby_parent_tags },
        user: { avatar_attachment: :blob }
      )
      .order(:id)
      .distinct
  end
end
