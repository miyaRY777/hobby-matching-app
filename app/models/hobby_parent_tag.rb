class HobbyParentTag < ApplicationRecord
  belongs_to :hobby
  belongs_to :parent_tag

  enum :room_type, { chat: 0, study: 1, game: 2 }

  validates :hobby_id, uniqueness: { scope: :room_type }
  validates :parent_tag_id, uniqueness: { scope: :hobby_id }

  before_validation :sync_room_type

  private

  def sync_room_type
    return unless parent_tag_id.present? && room_type.nil?

    self.room_type = parent_tag.room_type
  end
end
