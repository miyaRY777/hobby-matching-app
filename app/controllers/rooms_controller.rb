class RoomsController < ApplicationController
  # 責務: 公開部屋一覧と部屋ページ。招待リンクの期限は SharesController。
  include AuthorizesRoomShow
  before_action :authenticate_user!

  def index
    @rooms = Room.unlocked
                 .includes(issuer_profile: :user)
                 .order(created_at: :desc)
                 .page(params[:page]).per(10)

    @viewer_profile = current_user.profile
    @joined_room_ids = @viewer_profile&.joined_room_ids || []
    @issued_room_ids = @viewer_profile&.issued_room_ids || []
  end

  # 責務: 部屋を見せる。参加レコードは作らない。
  def show
    @room = Room.find(params[:id])
    authorize_room!

    @viewer_profile = current_user.profile
    @memberships = memberships_for_display
    @joined = joined_as_viewer?
    @jsmind_data = JsmindDataBuilder.new(@room, @memberships).build
  end

  private

  def joined_as_viewer?
    # ロード済みの @memberships を使う。Policy の exists? は見ない
    @viewer_profile.present? &&
      @memberships.any? { |membership| membership.profile_id == @viewer_profile.id }
  end

  def memberships_for_display
    # 地図用。N+1 を防ぐ includes を維持する
    @room.room_memberships
         .includes(profile: [ :user, { profile_hobbies: { hobby: :hobby_parent_tags } } ])
         .order(created_at: :asc)
  end
end
