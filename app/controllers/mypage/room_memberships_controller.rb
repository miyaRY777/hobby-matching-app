class Mypage::RoomMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership, only: :destroy

  def create
    profile = current_user.profile
    return redirect_to rooms_path, alert: "プロフィールを作成してください" unless profile

    @room = Room.unlocked.find(params[:room_id])
    RoomMembership.create!(room: @room, profile: profile)
    redirect_to room_redirect_path(@room), notice: "部屋に参加しました"
  rescue ActiveRecord::RecordNotFound
    redirect_to rooms_path, alert: "部屋が見つかりません"
  rescue ActiveRecord::RecordInvalid
    redirect_to rooms_path, alert: "すでに参加しています"
  end

  def destroy
    # 自分が作成した部屋からは退出できないようにする
    if @membership.room.issuer_profile == current_user.profile
      redirect_to mypage_rooms_path, alert: "作成した部屋からは退出できません"
      return
    end

    # membership（部屋参加者） を削除して退出する
    if @membership.destroy
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "部屋から退出しました" }
        format.html { redirect_to mypage_rooms_path, notice: "部屋から退出しました" }
      end
    else
      redirect_to mypage_rooms_path, alert: "退出に失敗しました"
    end
  end

  private

  # 自分の membership のみ取得（他者の membership は RecordNotFound になる）
  # room を eager load して N+1 を防ぐ
  def set_membership
    @membership = current_user.profile.room_memberships.includes(room: :issuer_profile).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to mypage_rooms_path, alert: "参加している部屋が見つかりません"
  end

  def room_redirect_path(room)
    return share_path(room.share_link.token) if room.shareable?

    mypage_rooms_path
  end
end
