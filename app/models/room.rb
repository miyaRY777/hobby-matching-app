class Room < ApplicationRecord
  enum :room_type, { chat: 0, study: 1, game: 2 }

  scope :locked,   -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }

  belongs_to :issuer_profile, class_name: "Profile", foreign_key: :issuer_profile_id, inverse_of: :issued_rooms
  validates :label, presence: true, length: { maximum: 50 }

  has_many :room_memberships, dependent: :destroy
  has_many :profiles, through: :room_memberships

  has_one :share_link, dependent: :destroy

  def shareable?
    share_link.present?
  end
end
