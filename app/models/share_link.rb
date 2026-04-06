class ShareLink < ApplicationRecord
  belongs_to :room

  # 内部フラグ: true のとき set_expires_at をスキップして expires_at: nil を保存する
  # コントローラの params から直接渡さないこと（create 時のみ有効）
  attr_accessor :no_expiry

  validates :room_id, uniqueness: true

  before_validation :set_token, on: :create
  before_validation :set_expires_at, on: :create

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end

  def set_expires_at
    return if no_expiry
    self.expires_at ||= 24.hours.from_now
  end
end
