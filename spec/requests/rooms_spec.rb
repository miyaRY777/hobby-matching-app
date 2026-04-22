require "rails_helper"

RSpec.describe "Rooms", type: :request do
  describe "GET /rooms" do
    context "ログインしている場合" do
      it "公開部屋一覧が表示される" do
        # セットアップ: ログインユーザーと公開部屋・ロック部屋を用意
        current_user = create(:user)
        create(:profile, user: current_user)
        owner_profile = create(:profile)
        create(:room, issuer_profile: owner_profile, label: "公開部屋", locked: false)
        create(:room, issuer_profile: owner_profile, label: "ロック部屋", locked: true)
        sign_in current_user

        # アクション: 部屋一覧にアクセス
        get rooms_path

        # アサーション: 公開部屋のみ表示される
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("公開部屋")
        expect(response.body).not_to include("ロック部屋")
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        # アクション: 未ログインで部屋一覧にアクセス
        get rooms_path

        # アサーション: ログイン画面へ遷移する
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /mypage/room_memberships" do
    context "ログインしている場合" do
      it "共有リンクがある公開部屋に参加すると共有ページへリダイレクトする" do
        # セットアップ: ログインユーザーと公開部屋を用意
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)
        share_link = create(:share_link, room:, token: "joined-room-token", expires_at: 1.year.from_now)
        sign_in current_user

        # アクション: 部屋参加リクエストを送る
        expect {
          post mypage_room_memberships_path, params: { room_id: room.id }
        }.to change(RoomMembership, :count).by(1)

        # アサーション: 参加情報が作成されて共有ページへ遷移する
        expect(response).to redirect_to(share_path(share_link.token))
        expect(RoomMembership.exists?(room:, profile: current_profile)).to be true
      end

      it "共有リンクがない公開部屋に参加するとマイページの部屋一覧へリダイレクトする" do
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)
        sign_in current_user

        expect {
          post mypage_room_memberships_path, params: { room_id: room.id }
        }.to change(RoomMembership, :count).by(1)

        expect(response).to redirect_to(mypage_rooms_path)
        expect(RoomMembership.exists?(room:, profile: current_profile)).to be true
      end

      it "重複参加しようとすると作成されない" do
        # セットアップ: すでに参加済みの状態を用意
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)
        create(:room_membership, room:, profile: current_profile)
        sign_in current_user

        # アクション: 同じ部屋に再参加する
        expect {
          post mypage_room_memberships_path, params: { room_id: room.id }
        }.not_to change(RoomMembership, :count)

        # アサーション: 一覧に戻り、エラーメッセージが設定される
        expect(response).to redirect_to(rooms_path)
        expect(flash[:alert]).to eq("すでに参加しています")
      end

      it "ロックされた部屋には参加できない" do
        # セットアップ: ログインユーザーとロック部屋を用意
        current_user = create(:user)
        create(:profile, user: current_user)
        owner_profile = create(:profile)
        locked_room = create(:room, issuer_profile: owner_profile, locked: true)
        sign_in current_user

        # アクション: ロック部屋に参加しようとする
        expect {
          post mypage_room_memberships_path, params: { room_id: locked_room.id }
        }.not_to change(RoomMembership, :count)

        # アサーション: 一覧に戻り、見つからない扱いになる
        expect(response).to redirect_to(rooms_path)
        expect(flash[:alert]).to eq("部屋が見つかりません")
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        # セットアップ: 参加対象の部屋を用意
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)

        # アクション: 未ログインで参加リクエストを送る
        post mypage_room_memberships_path, params: { room_id: room.id }

        # アサーション: ログイン画面へ遷移する
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
