# 責務: 部屋の閲覧可否（RoomPolicy#show?）。失敗は 404。410 は SharesController。
module AuthorizesRoomShow
  extend ActiveSupport::Concern

  included do
    rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized
  end

  private

  def authorize_room!
    authorize! @room, to: :show?
  end

  def handle_unauthorized
    head :not_found
  end
end
