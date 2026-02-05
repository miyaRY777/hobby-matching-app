class Hobby < ApplicationRecord
  has_many :profile_hobbies, dependent: :destroy
  has_many :profiles, through: :profile_hobbies

  validates :name, presence: true, uniqueness: true
end
