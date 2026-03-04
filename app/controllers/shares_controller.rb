# 共有リンク（token）で部屋に入るページを表示するために、必要なデータを集めてビューに渡すのが目的
class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    # token から共有リンクを取得（存在しなければ404）
    share_link = ShareLink.find_by!(token: params[:token])

    # 期限切れは「もう使えない共有リンク」として 410 Gone を返す
    return head :gone if share_link.expires_at <= Time.current

    # 表示対象の部屋 と 閲覧者のプロフィール
    @room = share_link.room
    @viewer_profile = current_user.profile

    # 共有リンク閲覧を「部屋参加」として扱い、未参加ならメンバーシップを作成
    RoomMembership.find_or_create_by!(room: @room, profile: @viewer_profile) if @viewer_profile

    # マインドマップ表示に必要な情報をまとめて取得（N+1回避）
    @memberships = @room.room_memberships
                        .includes(profile: [ :user, :hobbies ])
                        .order(created_at: :asc)

    # jsMind 用の node_tree データを生成してビューへ渡す
    @jsmind_data = build_jsmind_data(@room, @memberships)
  end

  private

  # jsMind の "node_tree" 形式に合わせて「趣味（親）→ユーザー（子）」のツリーを組み立てる
  # クリック時に右ペインを更新できるよう、ユーザーノードに member 詳細URL を data.url として埋め込む
  def build_jsmind_data(room, memberships)
    # 趣味 => その趣味を持つプロフィール一覧 を集計
    hobby_to_profiles = {}
    memberships.each do |membership|

      # 見た目を安定させるため、趣味名で並べ替えてから集計
      membership.profile.hobbies.sort_by(&:name).each do |hobby|
        (hobby_to_profiles[hobby] ||= []) << membership.profile
      end
    end

    # 画面の差分を安定させるため、趣味名→プロフィールIDの順で並べてノード化
    hobby_nodes = hobby_to_profiles.sort_by { |hobby, _| hobby.name }.map do |hobby, profiles|
      profile_nodes = profiles.sort_by(&:id).map do |profile|
        {
          # jsMindノードIDはツリー内で一意になる必要があるため、profile と hobby を組み合わせる
          id: "p_#{profile.id}_h_#{hobby.id}",
          topic: profile.user.nickname.presence || "no-name",
          data: { url: room_member_path(room_id: room.id, id: profile.id) }
        }
      end
      # ノードクリック時に叩くURL（Turbo Frameで詳細表示する想定）
      { id: "hobby_#{hobby.id}", topic: hobby.name, children: profile_nodes }
    end

    # jsMindが期待するルート付きツリー（format: node_tree）
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
