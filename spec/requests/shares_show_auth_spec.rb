require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "未ログイン時にログインへリダイレクトする" do
    room = create(:room)
    share_link = create(:share_link, room: room)

    get share_path(share_link.token)

    expect(response).to redirect_to(new_user_session_path)
  end
end
