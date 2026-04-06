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

      it "公開中の部屋に「公開中」バッジが表示される" do
        # 公開中の部屋を準備
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        create(:room, issuer_profile: current_profile, locked: false)
        sign_in current_user

        get mypage_rooms_path

        # 「公開中」バッジが表示されること
        expect(response.body).to include("公開中")
      end

      it "ロック中の部屋に「ロック中」バッジが表示される" do
        # ロック中の部屋を準備
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        create(:room, issuer_profile: current_profile, locked: true)
        sign_in current_user

        get mypage_rooms_path

        # 「ロック中」バッジが表示されること
        expect(response.body).to include("ロック中")
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

      it "参加中の部屋（他者が作成・自分がメンバー）が一覧に含まれる" do
        # ログインユーザーを作成
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)

        # 部屋の作成者を作成
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)

        # 作成者が作成した部屋を用意
        room_owners_room = create(:room, issuer_profile: room_owner_profile, label: "参加中テスト部屋")
        create(:share_link, room: room_owners_room)

        # ログインユーザーがその部屋に参加している状態を作る
        create(:room_membership, room: room_owners_room, profile: current_profile)

        # ログインしてアクセス
        sign_in current_user
        get mypage_rooms_path

        # 正常に表示されること
        expect(response).to have_http_status(:ok)

        # 参加中の部屋名が表示されること
        expect(response.body).to include("参加中テスト部屋")
      end
    end

    it "expires_at が nil の部屋があってもエラーにならない" do
      # ログインユーザーと紐づくプロフィールを用意
      current_user = create(:user)
      current_profile = create(:profile, user: current_user)

      # expires_at が nil の共有リンクを持つ部屋を用意
      own_room = create(:room, issuer_profile: current_profile)
      create(:share_link, room: own_room, expires_at: nil)
      sign_in current_user

      # 部屋一覧ページにアクセス
      get mypage_rooms_path

      # エラーなく表示されること
      expect(response).to have_http_status(:ok)
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

    it "room_type を指定して部屋を作成できる" do
      user = create(:user)
      create(:profile, user: user)
      sign_in user

      post mypage_rooms_path, params: { room: { label: "ゲーム部屋", room_type: "game" } }

      expect(Room.last.room_type).to eq("game")
    end

    it "room_type を指定しない場合は chat になる" do
      user = create(:user)
      create(:profile, user: user)
      sign_in user

      post mypage_rooms_path, params: { room: { label: "デフォルト部屋" } }

      expect(Room.last.room_type).to eq("chat")
    end

    it "expires_in: '7d' を指定すると ShareLink の expires_at が 7日後になる" do
      # ログインユーザーと紐づくプロフィールを用意
      current_user = create(:user)
      create(:profile, user: current_user)
      sign_in current_user

      # expires_in: "7d" を指定して部屋を作成
      post mypage_rooms_path, params: { room: { label: "部屋" }, expires_in: "7d" }

      # ShareLink の expires_at が 7日後になっていること
      expect(ShareLink.last.expires_at).to be_within(5.seconds).of(7.days.from_now)
    end

    it "expires_in: 'none' を指定すると ShareLink の expires_at が nil になる" do
      # ログインユーザーと紐づくプロフィールを用意
      current_user = create(:user)
      create(:profile, user: current_user)
      sign_in current_user

      # expires_in: "none" を指定して部屋を作成
      post mypage_rooms_path, params: { room: { label: "部屋" }, expires_in: "none" }

      # ShareLink の expires_at が nil になっていること
      expect(ShareLink.last.expires_at).to be_nil
    end

    it "locked: true を指定してロック状態で作成できる" do
      # ログインユーザーと紐づくプロフィールを用意
      current_user = create(:user)
      create(:profile, user: current_user)
      sign_in current_user

      # locked: true を指定して部屋を作成
      post mypage_rooms_path, params: { room: { label: "ロック部屋", locked: true } }

      # 作成された部屋が locked になっていること
      expect(Room.last.locked).to be true
    end

    it "プロフィール未作成のユーザーが部屋を作成しようとするとリダイレクトされる" do
      user = create(:user)
      sign_in user

      post mypage_rooms_path, params: { room: { label: "部屋" } }

      expect(response).to redirect_to(mypage_root_path)
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

  describe "PATCH /mypage/rooms/:id/lock" do
    context "オーナーがロックする場合" do
      it "locked が true になる" do
        # ログインユーザーと部屋を準備
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        own_room = create(:room, issuer_profile: current_profile, locked: false)
        sign_in current_user

        # ロックを実行
        patch lock_mypage_room_path(own_room)

        # locked が true になっていること
        expect(own_room.reload.locked).to be true
      end

      it "turbo_stream で応答する" do
        # ログインユーザーと部屋を準備
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        own_room = create(:room, issuer_profile: current_profile)
        sign_in current_user

        # turbo_stream リクエストを送信
        patch lock_mypage_room_path(own_room), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        # turbo_stream で応答すること
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "他人の部屋をロックしようとした場合" do
      it "404 を返す" do
        # ログインユーザーと他人の部屋を準備
        current_user = create(:user)
        create(:profile, user: current_user)
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        room_owners_room = create(:room, issuer_profile: room_owner_profile)
        sign_in current_user

        # 他人の部屋をロックしようとする
        patch lock_mypage_room_path(room_owners_room)

        # 404 が返ること
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /mypage/rooms/:id/unlock" do
    context "オーナーがロック解除する場合" do
      it "locked が false になる" do
        # ロック中の部屋を準備
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        own_room = create(:room, issuer_profile: current_profile, locked: true)
        sign_in current_user

        # ロック解除を実行
        patch unlock_mypage_room_path(own_room)

        # locked が false になっていること
        expect(own_room.reload.locked).to be false
      end

      it "他人の部屋はロック解除できない" do
        # ログインユーザーと他人のロック中部屋を準備
        current_user = create(:user)
        create(:profile, user: current_user)
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        room_owners_room = create(:room, issuer_profile: room_owner_profile, locked: true)
        sign_in current_user

        # 他人の部屋をロック解除しようとする
        patch unlock_mypage_room_path(room_owners_room)

        # 404 が返ること
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
