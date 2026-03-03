require "rails_helper"

RSpec.describe "Rooms::Members#show", type: :request do
  # 事前準備（User, Profile, Room）
  let(:issuer_user) { create(:user, nickname: "issuer_nick") }
  let(:issuer_profile) { create(:profile, user: issuer_user) }
  let(:room) { create(:room, issuer_profile: issuer_profile) }

  before do
    create(:room_membership, room: room, profile: issuer_profile)
  end

  describe "認可" do
    it "未ログインのとき、ログインページにリダイレクトされる" do
      get room_member_path(room_id: room.id, id: issuer_profile.id)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "ログイン済みでも部屋のメンバーでなければ403を返す" do
      other_user = create(:user)
      create(:profile, user: other_user)
      sign_in other_user

      get room_member_path(room_id: room.id, id: issuer_profile.id)

      expect(response).to have_http_status(:forbidden)
    end

    it "部屋のメンバーであれば200を返す" do
      sign_in issuer_user

      get room_member_path(room_id: room.id, id: issuer_profile.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "@shared_hobbies" do
    it "部屋の全メンバーの趣味の和集合のうち、対象profileが持つ趣味を返す" do
      # 事前準備
      viewer_user = create(:user, nickname: "viewer_nick")
      viewer_profile = create(:profile, user: viewer_user)
      create(:room_membership, room: room, profile: viewer_profile)

      hobby_a = create(:hobby, name: "登山")
      hobby_b = create(:hobby, name: "読書")

      issuer_profile.hobbies << [ hobby_a, hobby_b ]
      viewer_profile.hobbies << hobby_a

      # viewer視点で issuer の詳細ページを閲覧
      sign_in viewer_user
      get room_member_path(room_id: room.id, id: issuer_profile.id)

      # issuerが持つ趣味（和集合内のもの）が表示されることを確認
      expect(response.body).to include("登山")
      expect(response.body).to include("読書")
    end
  end
end
