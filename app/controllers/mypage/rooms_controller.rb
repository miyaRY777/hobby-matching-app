class Mypage::RoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: %i[edit update destroy lock unlock regenerate_share_link]

  def index
    @new_room = Room.new
    profile = current_user.profile
    @combined = profile ? MypageRoomsQuery.call(profile: profile, page: params[:page])
                        : Kaminari.paginate_array([]).page(params[:page]).per(MypageRoomsQuery::PER)
  end

  def create
    issuer_profile = current_user.profile
    return redirect_to mypage_root_path unless issuer_profile
    result = RoomCreator.call(
      issuer_profile: issuer_profile,
      room_params: room_create_params,
      expires_in: params[:expires_in]
    )
    unless result[:success]
      @new_room = result[:room]
      @combined = MypageRoomsQuery.call(profile: issuer_profile, page: params[:page])
      flash.now[:alert] = "部屋を作成できませんでした"
      return render :index, status: :unprocessable_entity
    end
    @room = result[:room]
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
    update_lock(true, "非公開にしました")
  end

  def unlock
    update_lock(false, "公開しました")
  end

  def regenerate_share_link
    @room = current_user.profile.issued_rooms
                        .includes(:share_link, :room_memberships)
                        .find(params[:id])
    @share_link = @room.share_link
    raise ActiveRecord::RecordNotFound, "ShareLink not found for room #{@room.id}" unless @share_link

    @share_link.regenerate!
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "招待リンクを再発行しました" }
      format.html { redirect_to mypage_rooms_path, notice: "招待リンクを再発行しました" }
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

  # create 専用（locked を含む）
  def room_create_params
    params.require(:room).permit(:label, :room_type, :locked)
  end

  # update 専用（locked は lock/unlock アクション経由でのみ変更）
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
