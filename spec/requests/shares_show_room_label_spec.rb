require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "部屋名が未入力の場合、デフォルト名を表示する" do
    # 発行者ユーザーとプロフィールを作成
    issuer_user = create(:user, nickname: "tana_A")
    issuer_profile = create(:profile, user: issuer_user)

    # 部屋名を空文字("")で作成（未入力状態を再現）
    room = create(:room, issuer_profile: issuer_profile, label: "")

    # 有効な共有リンクを作成
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    # 発行者を部屋に参加させる（初期メンバー）
    create(:room_membership, room: room, profile: issuer_profile)

    # ログインして共有ページへアクセス
    sign_in issuer_user
    get share_path(share_link.token)

    # 表示上は「名無しの部屋」が出力されることを確認
    expect(response.body).to include("名無しの部屋")
  end
end