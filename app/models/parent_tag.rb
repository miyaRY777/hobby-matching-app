class ParentTag < ApplicationRecord
  enum :room_type, { chat: 0, study: 1, game: 2 }

  has_many :hobbies, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :room_type }
end
