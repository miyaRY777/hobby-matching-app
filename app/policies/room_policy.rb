class RoomPolicy < ApplicationPolicy
  # 責務: 部屋の閲覧可否。招待リンクの期限は ShareLinkPolicy。
  # ActionPolicy は対象を record と呼ぶので、このクラスでは room として使う。

  def show?
    return true if member? || owner?

    !room.locked?
  end

  private

  def room
    record
  end

  def member?
    return @member if instance_variable_defined?(:@member)

    @member = viewer_profile.present? &&
      RoomMembership.exists?(room: room, profile: viewer_profile)
  end

  def owner?
    # 責務: この部屋を作った人かどうか判定。RoomMembership がなくても作成者なら許可する。
    viewer_profile&.id == room.issuer_profile_id
  end

  def viewer_profile
    return @viewer_profile if instance_variable_defined?(:@viewer_profile)

    @viewer_profile = user.profile
  end
end
