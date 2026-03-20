class Mypage::RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: %i[edit update destroy]

  def index
    profile = current_user.profile
    @rooms = if profile
      profile.issued_rooms.includes(:share_link, :room_memberships).order(created_at: :desc)
    else
      Room.none
    end
  end

  def create
    issuer_profile = current_user.profile

    Room.transaction do
      @room = Room.create!(
        issuer_profile: issuer_profile,
        label: params.dig(:room, :label)
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
    params.require(:room).permit(:label)
  end
end
