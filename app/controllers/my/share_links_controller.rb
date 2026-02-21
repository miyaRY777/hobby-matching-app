class My::ShareLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: %i[edit update destroy]

  def index
    profile = current_user.profile
    @rooms = profile ? profile.issued_rooms.includes(:share_link) : Room.none
  end

  def edit
  end

  # あとで、Service Objectに切り出す
  def create
    issuer_profile = current_user.profile

    Room.transaction do
      room = Room.create!(
        issuer_profile: issuer_profile,
        label: params.dig(:room, :label)
      )

      RoomMembership.create!(room: room, profile: issuer_profile)
      ShareLink.create!(room: room)
    end

    redirect_to my_share_links_path
  end

  def update
    if @room.update(room_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "部屋名を更新しました" } # update.turbo_stream.erb が描画される
        format.html { redirect_to my_share_links_path, notice: "部屋名を更新しました" }
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
      format.html { redirect_to my_share_links_path, notice: "部屋を削除しました" }
    end
  end

  private

  def set_room
    # 発行者だけが編集できるように絞る
    @room = current_user.profile.issued_rooms.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:label)
  end
end
