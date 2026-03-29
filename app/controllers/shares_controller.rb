# 共有リンク（token）から部屋ページを表示するコントローラ
# - トークン検証
# - 部屋参加処理
# - マインドマップ表示用データの準備
class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    # --------------------------------------------------
    # 1. 共有リンク取得（存在しない場合は 404）
    # --------------------------------------------------
    share_link = ShareLink.includes(:room).find_by!(token: params[:token])
    @viewer_profile = current_user.profile

    # --------------------------------------------------
    # 2. 有効期限チェック
    # 期限切れ かつ 未参加ユーザー → 410 Gone
    # 期限切れ かつ 既存メンバー → 通過（閲覧OK）
    # --------------------------------------------------
    if share_link.expired?
      return head :gone unless @viewer_profile && RoomMembership.exists?(room: share_link.room, profile: @viewer_profile)
    end

    # --------------------------------------------------
    # 3. 表示対象の部屋を取得
    # --------------------------------------------------
    @room = share_link.room

    # --------------------------------------------------
    # 4. 共有リンク閲覧を「部屋参加」として扱う
    # 未参加の場合のみ RoomMembership を作成
    # --------------------------------------------------
    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile

    # --------------------------------------------------
    # 5. マインドマップ表示用データ取得
    # includes により N+1 クエリを防止
    # --------------------------------------------------
    @memberships = @room.room_memberships
                        .includes(profile: [ :user, { profile_hobbies: :hobby } ])
                        .order(created_at: :asc)

    # --------------------------------------------------
    # 6. jsMind 用データ生成
    # --------------------------------------------------
    @jsmind_data = build_jsmind_data(@room, @memberships)
  end

  private

  # --------------------------------------------------
  # jsMind 用の node_tree 形式データを生成
  #
  # 構造
  #   趣味（親ノード）
  #      └ ユーザー（子ノード）
  #
  # ユーザーノードには member 詳細ページのURLを持たせ、
  # クリック時に Turbo Frame で右ペインを更新できるようにする
  # --------------------------------------------------
  def build_jsmind_data(room, memberships)
    # --------------------------------------------------
    # 趣味 => その趣味を持つプロフィール一覧
    # --------------------------------------------------
    hobby_to_profiles = {}

    memberships.each do |membership|
      # 表示順を安定させるため趣味名でソート
      membership.profile.hobbies.sort_by(&:name).each do |hobby|
        (hobby_to_profiles[hobby] ||= []) << membership.profile
      end
    end

    # --------------------------------------------------
    # jsMind ノード生成
    # - 趣味名順
    # - プロフィールID順
    # --------------------------------------------------
    hobby_nodes = hobby_to_profiles.sort_by { |hobby, _| hobby.name }.map do |hobby, profiles|
      profile_nodes = profiles.sort_by(&:id).map do |profile|
        {
          # jsMind ノードIDはツリー内で一意である必要がある
          id: "p_#{profile.id}_h_#{hobby.id}",
          topic: profile.user.nickname.presence || "no-name",

          # ノードクリック時に呼び出すメンバー詳細URL
          data: { url: room_member_path(room_id: room.id, id: profile.id) }
        }
      end

      # 趣味ノード（親）
      { id: "hobby_#{hobby.id}", topic: hobby.name, children: profile_nodes }
    end

    # --------------------------------------------------
    # jsMind が期待するルート付きツリー構造
    # --------------------------------------------------
    {
      meta: { name: "room-map", version: "0.2" },
      format: "node_tree",
      data: {
        id: "root",
        isroot: true,
        topic: room.label.presence || "この部屋の趣味",
        children: hobby_nodes
      }
    }
  end
end
