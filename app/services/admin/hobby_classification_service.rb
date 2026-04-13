class Admin::HobbyClassificationService
  def self.call(hobby:, parent_tag:)
    ApplicationRecord.transaction do
      hobby_parent_tag = hobby.hobby_parent_tags.find_by(room_type: parent_tag.room_type)

      if hobby_parent_tag
        hobby_parent_tag.update!(parent_tag:)
      else
        hobby.hobby_parent_tags.create!(parent_tag:)
      end
    end
  end

  # room_type ごとの parent_tag_id を一括処理する。parent_tags を一括取得して N+1 を防ぐ。
  # room_type_to_parent_tag_id: { "chat" => "1", "study" => "", "game" => "3" } のような Hash
  def self.call_bulk(hobby:, room_type_to_parent_tag_id:)
    ids = room_type_to_parent_tag_id.values.reject(&:blank?).map(&:to_i)
    return if ids.empty?

    parent_tags = ParentTag.where(id: ids).index_by { |pt| pt.id.to_s }

    ApplicationRecord.transaction do
      room_type_to_parent_tag_id.each_value do |parent_tag_id|
        next if parent_tag_id.blank?

        parent_tag = parent_tags[parent_tag_id.to_s]
        next unless parent_tag

        call(hobby:, parent_tag:)
      end
    end
  end
end
