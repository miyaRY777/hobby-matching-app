class Profile < ApplicationRecord
  belongs_to :user
  validates :user_id, uniqueness: true
  validates :bio, presence: true, length: { maximum: 500 }

  has_many :profile_hobbies, dependent: :destroy
  has_many :hobbies, through: :profile_hobbies
end
