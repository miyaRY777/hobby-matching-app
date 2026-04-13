class ParentTag < ApplicationRecord
  enum :room_type, { chat: 0, study: 1, game: 2 }

  scope :classified, -> { where.not(room_type: nil) }

  has_many :hobby_parent_tags, dependent: :restrict_with_error
  has_many :hobbies, through: :hobby_parent_tags

  validates :name, presence: true, uniqueness: { scope: :room_type }
  validates :slug, presence: true, uniqueness: { scope: :room_type }
end
