class Room < ApplicationRecord
  belongs_to :issuer_profile, class_name: "Profile"

  has_many :room_memberships, dependent: :destroy
  has_many :profiles, through: :room_memberships

  has_one :share_link, dependent: :destroy
end
