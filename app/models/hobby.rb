class Hobby < ApplicationRecord
  scope :unclassified, -> { left_joins(:hobby_parent_tags).where(hobby_parent_tags: { id: nil }) }

  has_many :hobby_parent_tags, dependent: :destroy
  has_many :parent_tags, through: :hobby_parent_tags

  def primary_room_type
    hobby_parent_tags.min_by { |hpt| HobbyParentTag.room_types[hpt.room_type] }&.room_type || "unclassified"
  end

  def primary_parent_tag_info
    primary = hobby_parent_tags.min_by { |hpt| HobbyParentTag.room_types[hpt.room_type] }
    { parent_tag_name: primary&.parent_tag&.name, room_type: primary&.room_type }
  end

  def unused?
    usage_count.to_i == 0
  end

  has_many :profile_hobbies, dependent: :restrict_with_error
  has_many :profiles, through: :profile_hobbies

  validates :name, presence: true, uniqueness: true

  before_save :set_normalized_name

  def self.normalize(name)
    name.to_s.unicode_normalize(:nfkc).strip.downcase
  end

  private

  def set_normalized_name
    self.normalized_name = self.class.normalize(name)
  end
end
