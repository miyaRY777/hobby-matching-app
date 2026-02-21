require "rails_helper"

RSpec.describe "My::ShareLinks#index", type: :request do
  it "デフォルト名の部屋と共有URLを表示する" do
    # ユーザーとプロフィールを用意する
    user = create(:user)
    profile = create(:profile, user: user)
    sign_in user

    # 発行者として部屋を作る（label空）
    room = create(:room, issuer_profile: profile, label: "")
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    get my_share_links_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("名無しの部屋")
    expect(response.body).to include("/share/#{share_link.token}")
  end
end
