class Profile < ApplicationRecord
  belongs_to :user
  validates :user_id, uniqueness: true
  validates :bio, presence: true, length: { maximum: 500 }
end
