require "rails_helper"

RSpec.describe "Mypage::Rooms", type: :request do
  describe "GET /mypage/rooms" do
    context "ログインしている場合" do
      it "自分が作成した部屋一覧が表示される" do
        user = create(:user)
        profile = create(:profile, user: user)
        room = create(:room, issuer_profile: profile, label: "テスト部屋")
        create(:share_link, room: room)
        sign_in user

        get mypage_rooms_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("テスト部屋")
      end

      it "新しい順で表示される" do
        user = create(:user)
        profile = create(:profile, user: user)
        old_room = create(:room, issuer_profile: profile, label: "古い部屋", created_at: 1.day.ago)
        new_room = create(:room, issuer_profile: profile, label: "新しい部屋", created_at: Time.current)
        sign_in user

        get mypage_rooms_path

        expect(response.body.index("新しい部屋")).to be < response.body.index("古い部屋")
      end

      it "他人の部屋は表示されない" do
        user = create(:user)
        create(:profile, user: user)
        other_user = create(:user)
        other_profile = create(:profile, user: other_user)
        create(:room, issuer_profile: other_profile, label: "他人の部屋")
        sign_in user

        get mypage_rooms_path

        expect(response.body).not_to include("他人の部屋")
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        get mypage_rooms_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /mypage/rooms" do
    it "部屋・メンバーシップ・共有リンクが作成される" do
      user = create(:user)
      profile = create(:profile, user: user)
      sign_in user

      expect {
        post mypage_rooms_path, params: { room: { label: "新しい部屋" } }
      }.to change(Room, :count).by(1)
        .and change(RoomMembership, :count).by(1)
        .and change(ShareLink, :count).by(1)
    end

    it "作成後に部屋一覧にリダイレクトされる" do
      user = create(:user)
      create(:profile, user: user)
      sign_in user

      post mypage_rooms_path, params: { room: { label: "新しい部屋" } }

      expect(response).to redirect_to(mypage_rooms_path)
    end
  end

  describe "PATCH /mypage/rooms/:id" do
    it "部屋名を更新できる" do
      user = create(:user)
      profile = create(:profile, user: user)
      room = create(:room, issuer_profile: profile, label: "旧名")
      sign_in user

      patch mypage_room_path(room), params: { room: { label: "新名" } }

      expect(room.reload.label).to eq("新名")
    end

    it "他人の部屋は編集できない" do
      user = create(:user)
      create(:profile, user: user)
      other_user = create(:user)
      other_profile = create(:profile, user: other_user)
      room = create(:room, issuer_profile: other_profile, label: "他人の部屋")
      sign_in user

      patch mypage_room_path(room), params: { room: { label: "乗っ取り" } }

      expect(response).to have_http_status(:not_found)
      expect(room.reload.label).to eq("他人の部屋")
    end
  end

  describe "DELETE /mypage/rooms/:id" do
    it "部屋を削除できる" do
      user = create(:user)
      profile = create(:profile, user: user)
      room = create(:room, issuer_profile: profile)
      sign_in user

      expect {
        delete mypage_room_path(room)
      }.to change(Room, :count).by(-1)
    end

    it "他人の部屋は削除できない" do
      user = create(:user)
      create(:profile, user: user)
      other_user = create(:user)
      other_profile = create(:profile, user: other_user)
      room = create(:room, issuer_profile: other_profile)
      sign_in user

      delete mypage_room_path(room)

      expect(response).to have_http_status(:not_found)
    end
  end
end
