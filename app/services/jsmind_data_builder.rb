class JsmindDataBuilder
  include Rails.application.routes.url_helpers

  def initialize(room, memberships)
    @room        = room
    @memberships = memberships
  end

  def build
    {
      meta:   { name: "room-map", version: "0.2" },
      format: "node_tree",
      data:   {
        id:       "root",
        isroot:   true,
        topic:    @room.label.presence || "この部屋の趣味",
        children: build_children
      }
    }
  end

  private

  def build_children
    (parent_tag_nodes + [ other_node ]).compact
  end

  def parent_tag_nodes
    matching_parent_tags.filter_map do |parent_tag|
      profiles = profiles_for(parent_tag)
      next if profiles.empty?

      {
        id:       "pt_#{parent_tag.id}",
        topic:    parent_tag.name,
        children: user_nodes_for(profiles, "pt_#{parent_tag.id}")
      }
    end
  end

  def other_node
    profiles = profiles_without_matching_hobby
    return if profiles.empty?

    {
      id:       "other",
      topic:    "その他",
      expanded: false,
      children: user_nodes_for(profiles, "other")
    }
  end

  def matching_parent_tags
    @matching_parent_tags ||= ParentTag.where(room_type: @room.room_type).order(:position)
  end

  def matching_parent_tag_ids
    @matching_parent_tag_ids ||= matching_parent_tags.map(&:id)
  end

  # room_memberships は DB 制約でユニーク保証済みだが、防御的に uniq を適用
  # 呼び出し元で以下の includes が必須（未設定時に N+1 が発生する）:
  #   includes(profile: [:user, { profile_hobbies: { hobby: :hobby_parent_tags } }])
  def all_profiles
    @all_profiles ||= @memberships.map(&:profile).uniq(&:id)
  end

  def profiles_for(parent_tag)
    profiles_by_parent_tag_id[parent_tag.id].uniq(&:id)
  end

  def profiles_without_matching_hobby
    matched_ids = matching_parent_tag_ids
      .flat_map { |id| profiles_by_parent_tag_id[id] }
      .map(&:id).to_set
    all_profiles.reject { |p| matched_ids.include?(p.id) }
  end

  # parent_tag_id → [profile] の Hash をメモ化（O(1) ルックアップ用）
  def profiles_by_parent_tag_id
    @profiles_by_parent_tag_id ||=
      all_profiles.each_with_object(Hash.new { |h, k| h[k] = [] }) do |profile, hash|
        profile.profile_hobbies.each do |profile_hobby|
          profile_hobby.hobby.hobby_parent_tags.each do |hobby_parent_tag|
            hash[hobby_parent_tag.parent_tag_id] << profile
          end
        end
      end
  end

  def user_nodes_for(profiles, parent_key)
    profiles.sort_by(&:id).map do |profile|
      {
        id:    "p_#{profile.id}_#{parent_key}",
        topic: profile.user.nickname.presence || "no-name",
        data:  { url: room_member_path(room_id: @room.id, id: profile.id) }
      }
    end
  end
end
