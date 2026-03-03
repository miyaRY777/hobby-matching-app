module Rooms
  class MembersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room
    before_action :authorize_member!

    def show
      @profile = Profile.includes(:user, :hobbies).find(params[:id])

      # 部屋メンバーが所有している趣味の ID 集合を取得する

      # - Hobby を起点に profiles と JOIN
      # - 現在の部屋に所属している profile_ids のみを対象に絞り込み
      # - 同一趣味を複数メンバーが持っている場合に備えて distinct を付与

      # ※ 「部屋という文脈内に存在する趣味」のみに表示を制限する設計
      room_hobby_ids = Hobby.joins(:profiles)
                            .where(profiles: { id: @room.profile_ids })
                            .select(:id)
                            .distinct

      # 対象プロフィールの趣味 ∩ 部屋に存在する趣味 を算出
      # → 部屋内で意味を持つ趣味のみを表示する
      @shared_hobbies = @profile.hobbies.where(id: room_hobby_ids)
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end

    def authorize_member!
      return if current_user.profile && RoomMembership.exists?(room: @room, profile: current_user.profile)

      head :forbidden
    end
  end
end
