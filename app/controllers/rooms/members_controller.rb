module Rooms
  # 部屋ページの「メンバー詳細表示」を担当するコントローラ
  #
  # 役割
  # - 部屋メンバーのプロフィールを取得
  # - 「部屋という文脈で意味のある趣味」だけを表示する
  # - 部屋に参加していないユーザーのアクセスを防ぐ
  class MembersController < ApplicationController
    # 未ログインユーザーのアクセスを防止
    before_action :authenticate_user!

    # URLの room_id から対象の部屋を取得
    before_action :set_room

    # 部屋メンバー以外のアクセスを禁止
    before_action :authorize_member!

    def show
      # --------------------------------------------------
      # 1. 表示対象プロフィールを取得
      # user / hobbies を eager load して N+1 クエリを防ぐ
      # --------------------------------------------------
      @profile = Profile.includes(:user, profile_hobbies: { hobby: :parent_tag }).find(params[:id])

      # --------------------------------------------------
      # 2. 部屋のroom_typeに一致する親タグを持つ子タグのみ抽出
      #
      # Room と ParentTag は同一の room_type enum を持つため
      # メモリ内で比較可能。eager load 済みなので追加クエリなし。
      # --------------------------------------------------
      @room_related_phs = @profile.profile_hobbies.select do |ph|
        ph.hobby.parent_tag&.room_type == @room.room_type
      end
    end

    private

    # --------------------------------------------------
    # URLの room_id から部屋を取得
    # --------------------------------------------------
    def set_room
      @room = Room.find(params[:room_id])
    end

    # --------------------------------------------------
    # 部屋メンバーのみアクセス可能にする認可処理
    #
    # 条件
    # - current_user がプロフィールを持つ
    # - そのプロフィールが RoomMembership に存在する
    #
    # 条件を満たさない場合は 403 Forbidden を返す
    # --------------------------------------------------
    def authorize_member!
      return if current_user.profile &&
                RoomMembership.exists?(room: @room, profile: current_user.profile)

      head :forbidden
    end
  end
end
