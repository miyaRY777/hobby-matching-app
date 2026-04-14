require "rails_helper"

RSpec.describe "shares#show", type: :request do
  it "部屋名が入力されている場合、その名前を表示する" do
    # 発行者ユーザーとプロフィールを作成
    issuer_user = create(:user, nickname: "tana_A")
    issuer_profile = create(:profile, user: issuer_user)

    # 部屋名を指定して作成（label は必須バリデーションが追加されたため空文字不可）
    room = create(:room, issuer_profile: issuer_profile, label: "テスト部屋")

    # 有効な共有リンクを作成
    share_link = create(:share_link, room: room, expires_at: 1.hour.from_now)

    # 発行者を部屋に参加させる（初期メンバー）
    create(:room_membership, room: room, profile: issuer_profile)

    # ログインして共有ページへアクセス
    sign_in issuer_user
    get share_path(share_link.token)

    # 指定した部屋名が表示されることを確認
    expect(response.body).to include("テスト部屋")
  end
end
