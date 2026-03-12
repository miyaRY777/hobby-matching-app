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
      @profile = Profile.includes(:user, profile_hobbies: :hobby).find(params[:id])
      @profile_hobby_map = @profile.profile_hobbies.index_by(&:hobby_id)

      # --------------------------------------------------
      # 2. 部屋メンバーが持っている趣味のID集合を取得
      #
      # 処理内容
      # - Hobby を起点に profiles テーブルと JOIN
      # - 現在の部屋に所属するプロフィールのみ対象
      # - 同一趣味を複数人が持つ可能性があるため distinct
      #
      # 目的
      # 「部屋という文脈で存在する趣味」を定義する
      # --------------------------------------------------
      room_hobby_ids = Hobby.joins(:profiles)
                            .where(profiles: { id: @room.profile_ids })
                            .select(:id)
                            .distinct

      # --------------------------------------------------
      # 3. 表示する趣味を決定
      #
      # 計算
      #   プロフィールの趣味 ∩ 部屋の趣味
      #
      # 例
      #   部屋の趣味 : [ゲーム, 釣り, 読書]
      #   ユーザーB : [ゲーム]
      #
      #   → 表示 : [ゲーム]
      #
      # 目的
      # 「部屋の話題として意味のある趣味」だけを表示する
      # --------------------------------------------------
      @shared_hobbies = @profile.hobbies.where(id: room_hobby_ids)
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
