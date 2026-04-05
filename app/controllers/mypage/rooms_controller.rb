class Mypage::RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: %i[edit update destroy lock unlock]

  def index
    profile = current_user.profile
    unless profile
      @rooms = Room.none
      @memberships = RoomMembership.none
      return
    end

    # 自分が作成した部屋一覧
    @rooms = profile.issued_rooms
                    .includes(:share_link, :room_memberships)
                    .order(created_at: :desc)

    # 自分が参加中の部屋（自分が作成者の部屋は除く）
    @memberships = profile.room_memberships
                          .joins(:room)
                          .where.not(rooms: { issuer_profile_id: profile.id })
                          .includes(room: [ { issuer_profile: :user }, :room_memberships, :share_link ])
                          .order("rooms.created_at DESC")
  end

  def create
    issuer_profile = current_user.profile
    return redirect_to mypage_root_path unless issuer_profile

    Room.transaction do
      @room = Room.create!(
        room_params.merge(issuer_profile: issuer_profile)
      )

      RoomMembership.create!(room: @room, profile: issuer_profile)
      ShareLink.create!(room: @room)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to mypage_rooms_path }
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "部屋名を更新しました" }
        format.html { redirect_to mypage_rooms_path, notice: "部屋名を更新しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def lock
    update_lock(true, "部屋をロックしました")
  end

  def unlock
    update_lock(false, "部屋のロックを解除しました")
  end

  def destroy
    @room.destroy!
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "部屋を削除しました" }
      format.html { redirect_to mypage_rooms_path, notice: "部屋を削除しました" }
    end
  end

  private

  def set_room
    @room = current_user.profile.issued_rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:label, :room_type)
  end

  def update_lock(state, message)
    @room.update!(locked: state)
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = message }
      format.html { redirect_to mypage_rooms_path, notice: message }
    end
  end
end
