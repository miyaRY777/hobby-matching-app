class ProfileHobby < ApplicationRecord
  belongs_to :profile
  belongs_to :hobby

  validates :hobby_id, uniqueness: {scope: :profile_id}
end
