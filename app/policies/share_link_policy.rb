class ShareLinkPolicy < ApplicationPolicy
  # 責務: 入場券（ShareLink）の案内可否。部屋の見る権利は RoomPolicy。
  # 期限切れの未参加はその URL では通せない。参加判定は持たない。

  def show?
    return true if member? || owner?
    return false if record.expired?

    !record.room.locked?
  end

  private

  def member?
    return @member if instance_variable_defined?(:@member)

    @member = viewer_profile.present? &&
      RoomMembership.exists?(room: record.room, profile: viewer_profile)
  end

  def owner?
    viewer_profile&.id == record.room.issuer_profile_id
  end

  def viewer_profile
    return @viewer_profile if instance_variable_defined?(:@viewer_profile)

    @viewer_profile = user.profile
  end
end
