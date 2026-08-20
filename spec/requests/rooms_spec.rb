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

  # ここで見ること: 200 / 404 と、覗いても参加しないこと
  # ここでは見ないこと: マインドマップの中身
  describe "GET /rooms/:id" do
    # 部屋の作成者
    let(:room_owner_user) { create(:user) }
    let(:room_owner_profile) { create(:profile, user: room_owner_user) }
    let(:public_room) { create(:room, issuer_profile: room_owner_profile, locked: false) }
    let(:private_room) { create(:room, issuer_profile: room_owner_profile, locked: true) }
    # 部屋作成者以外の閲覧者
    let(:current_user) { create(:user) }
    let(:current_profile) { create(:profile, user: current_user) }

    context "ログインしている場合" do
      context "公開部屋の場合" do
        before { sign_in current_user }
        it "未参加でも 200 を返す" do
          # セットアップ: プロフィールはあるが RoomMembership はない（覗くだけ）
          current_profile

          # アクション: 部屋ページを開く
          get room_path(public_room)

          # アサーション: 参加していなくても見られる
          expect(response).to have_http_status(:ok)
        end

        it "未参加でも RoomMembership は増えない" do
          # セットアップ: 覗く前の件数を確定させる
          current_profile
          public_room

          # アクション: 部屋ページを開く
          expect {
            get room_path(public_room)
          }.not_to change(RoomMembership, :count)
        end

        it "プロフィール未作成でも 200 を返す" do
          # セットアップ: current_profile は作らない（見るだけなら不要）

          # アクション: 部屋ページを開く
          get room_path(public_room)

          # アサーション: プロフィールなしでも覗ける
          expect(response).to have_http_status(:ok)
        end
      end

      context "非公開部屋の場合" do
        before { sign_in current_user }
        it "未参加は 404 を返す" do
          # セットアップ: プロフィールはあるが未参加
          current_profile

          # アクション: 非公開の部屋ページを開く
          get room_path(private_room)

          # アサーション: 外には存在しない扱い
          expect(response).to have_http_status(:not_found)
        end

        it "既存メンバーは 200 を返す" do
          # セットアップ: すでに中にいる人
          create(:room_membership, room: private_room, profile: current_profile)

          # アクション: 非公開の部屋ページを開く
          get room_path(private_room)

          # アサーション: 非公開でも見続けられる
          expect(response).to have_http_status(:ok)
        end
      end

      context "非公開部屋の作成者の場合" do
        before { sign_in room_owner_user }

        it "200 を返す" do
          # セットアップ: membership は作らない

          # アクション: 非公開の部屋ページを開く
          get room_path(private_room)

          # アサーション: 参加者でなくても作成者は見られる
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        # アクション: 未ログインで部屋ページを開く
        get room_path(public_room)

        # アサーション: ログイン画面へ遷移する
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /mypage/room_memberships" do
    context "ログインしている場合" do
      it "公開部屋に参加すると部屋ページへリダイレクトする" do
        # セットアップ: ログインユーザーと公開部屋を用意
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)
        create(:share_link, room:, token: "joined-room-token", expires_at: 1.year.from_now)
        sign_in current_user

        # アクション: 部屋参加リクエストを送る
        expect {
          post mypage_room_memberships_path, params: { room_id: room.id }
        }.to change(RoomMembership, :count).by(1)

        # アサーション: 参加情報が作成されて同じ部屋ページへ戻る
        expect(response).to redirect_to(room_path(room))
        expect(RoomMembership.exists?(room:, profile: current_profile)).to be true
      end

      it "共有リンクがない公開部屋に参加しても部屋ページへリダイレクトする" do
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        owner_profile = create(:profile)
        room = create(:room, issuer_profile: owner_profile, locked: false)
        sign_in current_user

        expect {
          post mypage_room_memberships_path, params: { room_id: room.id }
        }.to change(RoomMembership, :count).by(1)

        expect(response).to redirect_to(room_path(room))
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
