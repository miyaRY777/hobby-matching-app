class ShareLinkPolicy < ApplicationPolicy
  # user   = current_user（action_policy が自動注入）
  # record = share_link

  # 期限切れでも既存メンバーなら閲覧継続可
  def show?
    !record.expired? || member?
  end

  # ロック中は既存メンバー or オーナーのみ参加可
  def join?
    !record.room.locked? || member? || owner?
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
    user.profile
  end
end
