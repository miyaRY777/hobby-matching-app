class SharesController < ApplicationController
  # 責務: 入場券の判定と部屋への案内。地図は RoomsController。
  before_action :authenticate_user!
  rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

  # 責務: 券が通れば部屋へ案内する。参加レコードは作らない。
  def show
    @share_link = ShareLink.includes(:room).find_by!(token: params[:token])
    authorize! @share_link, to: :show?
    cookies[:recent_room_token] = { value: params[:token], expires: 1.year.from_now }

    redirect_to room_path(@share_link.room)
  end

  private

  # 責務: 期限切れは 410。それ以外の拒否は 404。
  def handle_unauthorized
    return head :gone if @share_link&.expired?

    head :not_found
  end
end
