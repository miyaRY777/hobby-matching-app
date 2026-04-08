# 共有リンク（token）から部屋ページを表示するコントローラ
# 主な責務：
#   1. トークンの有効性検証（存在・有効期限）
#   2. ロック状態に応じた参加制御
#   3. 入室処理（RoomMembership の作成）
#   4. マインドマップ表示用データの準備
class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    share_link      = ShareLink.includes(:room).find_by!(token: params[:token])
    @room           = share_link.room
    @viewer_profile = current_user.profile

    # 期限切れの場合は未参加者のみ 410 Gone を返す。
    # 既存メンバーはリンクが切れていても閲覧を継続できる。
    if share_link.expired?
      return head :gone unless @viewer_profile && RoomMembership.exists?(room: @room, profile: @viewer_profile)
    end

    # ロック中の部屋は未参加・非オーナーの入室を拒否する。
    # ページ自体は表示し、flash で理由を伝える（完全な 403 ではなく閲覧は許容）。
    # 既存メンバー・オーナーはロック状態に関わらず通過する。
    if @room.locked?
      already_member = @viewer_profile && RoomMembership.exists?(room: @room, profile: @viewer_profile)
      is_owner       = @viewer_profile&.id == @room.issuer_profile_id

      unless already_member || is_owner
        flash.now[:alert] = "この部屋は現在ロック中のため参加できません"
        @memberships = memberships_for_display
        @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
        return render :show
      end
    end

    # 初回アクセス時に入室処理を行う。
    # find_or_create_by! により二重参加は発生しない。
    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile

    @memberships = memberships_for_display
    @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
  end

  private

  # マインドマップ表示に必要な membership 一覧を取得する。
  # includes で N+1 を防止する。
  def memberships_for_display
    @room.room_memberships
         .includes(profile: [ :user, { profile_hobbies: { hobby: :parent_tag } } ])
         .order(created_at: :asc)
  end
end
