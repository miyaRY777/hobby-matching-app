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
        @jsmind_data = build_jsmind_data(@room, @memberships)
        return render :show
      end
    end

    # 初回アクセス時に入室処理を行う。
    # find_or_create_by! により二重参加は発生しない。
    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile

    @memberships = memberships_for_display
    @jsmind_data = build_jsmind_data(@room, @memberships)
  end

  private

  # マインドマップ表示に必要な membership 一覧を取得する。
  # includes で N+1 を防止する。
  def memberships_for_display
    @room.room_memberships
         .includes(profile: [ :user, { profile_hobbies: { hobby: :parent_tag } } ])
         .order(created_at: :asc)
  end

  # jsMind 用の node_tree 形式データを生成する。
  #
  # ノード構造:
  #   root
  #   └ 趣味ノード（hobby_#{id}）
  #       └ ユーザーノード（p_#{profile_id}_h_#{hobby_id}）
  #
  # ユーザーノードの data.url はクリック時に Turbo Frame で
  # 右ペインのメンバー詳細を更新するために使用する。
  def build_jsmind_data(room, memberships)
    hobby_to_profiles = {}

    memberships.each do |membership|
      # 趣味名でソートして表示順を安定させる
      membership.profile.hobbies.sort_by(&:name).each do |hobby|
        (hobby_to_profiles[hobby] ||= []) << membership.profile
      end
    end

    hobby_nodes = hobby_to_profiles.sort_by { |hobby, _| hobby.name }.map do |hobby, profiles|
      profile_nodes = profiles.sort_by(&:id).map do |profile|
        {
          id:    "p_#{profile.id}_h_#{hobby.id}", # ツリー内で一意である必要がある
          topic: profile.user.nickname.presence || "no-name",
          data:  { url: room_member_path(room_id: room.id, id: profile.id) }
        }
      end

      { id: "hobby_#{hobby.id}", topic: hobby.name, children: profile_nodes }
    end

    {
      meta:   { name: "room-map", version: "0.2" },
      format: "node_tree",
      data:   {
        id:       "root",
        isroot:   true,
        topic:    room.label.presence || "この部屋の趣味",
        children: hobby_nodes
      }
    }
  end
end
