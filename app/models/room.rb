class Room < ApplicationRecord
  belongs_to :issuer_profile, class_name: "Profile", foreign_key: :issuer_profile_id, inverse_of: :issued_rooms

  has_many :room_memberships, dependent: :destroy
  has_many :profiles, through: :room_memberships

  has_one :share_link, dependent: :destroy
end
