class ProfileHobby < ApplicationRecord
  belongs_to :profile
  belongs_to :hobby

  validates :hobby_id, uniqueness: { scope: :profile_id }
  validates :description, length: { maximum: 200 }, allow_blank: true
end
