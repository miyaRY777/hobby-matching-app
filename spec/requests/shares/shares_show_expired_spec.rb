require "rails_helper"

RSpec.describe "shares#show", type: :request do
  context "リンクが期限切れの場合" do
    it "未参加ユーザーは 410 Gone が返り、参加できない" do
      issuer = create(:profile)
      room = create(:room, issuer_profile: issuer)
      share_link = create(:share_link, room: room, expires_at: 1.minute.ago)

      viewer = create(:user)
      create(:profile, user: viewer)

      sign_in viewer

      expect {
        get share_path(share_link.token)
      }.not_to change(RoomMembership, :count)

      expect(response).to have_http_status(:gone)
    end

    it "既存メンバーは正常に部屋ページを表示できる" do
      issuer = create(:profile)
      room = create(:room, issuer_profile: issuer)
      share_link = create(:share_link, room: room, expires_at: 1.minute.ago)

      viewer = create(:user)
      viewer_profile = create(:profile, user: viewer)
      create(:room_membership, room: room, profile: viewer_profile)

      sign_in viewer

      get share_path(share_link.token)

      expect(response).to have_http_status(:ok)
    end

    it "プロフィール未登録ユーザーはプロフィール作成ページへリダイレクトされる" do
      issuer = create(:profile)
      room = create(:room, issuer_profile: issuer)
      share_link = create(:share_link, room: room, expires_at: 1.minute.ago)

      viewer = create(:user)
      # プロフィールを作成しない

      sign_in viewer

      get share_path(share_link.token)

      # プロフィール未作成ガードが期限切れチェックより先に動作するため、
      # 410 Gone ではなくプロフィール作成ページへのリダイレクトになる
      expect(response).to redirect_to(new_my_profile_path)
    end
  end
end
