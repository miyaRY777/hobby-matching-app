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
end
