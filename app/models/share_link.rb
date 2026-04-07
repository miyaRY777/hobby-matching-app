class ShareLink < ApplicationRecord
  belongs_to :room

  EXPIRES_IN_MAP = {
    "1h"  => 1.hour,
    "24h" => 24.hours,
    "3d"  => 3.days,
    "7d"  => 7.days
  }.freeze

  validates :room_id, uniqueness: true
  validates :expires_in, inclusion: { in: EXPIRES_IN_MAP.keys }, allow_nil: true

  before_validation :set_token, on: :create

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def regenerate!
    duration = EXPIRES_IN_MAP[expires_in]
    update!(
      token:      SecureRandom.urlsafe_base64(16),
      expires_at: duration ? duration.from_now : nil
    )
  end

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
