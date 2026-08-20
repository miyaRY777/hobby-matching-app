require "rails_helper"

RSpec.describe "Shares", type: :request do
  describe "GET /share/:token" do
    context "ロック中の部屋に未参加ユーザーがアクセスした場合" do
      it "404 を返し RoomMembership は作成されない" do
        # ロック中の部屋と共有リンクを準備
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        locked_room = create(:room, issuer_profile: room_owner_profile, locked: true)
        share_link = create(:share_link, room: locked_room, expires_at: 1.year.from_now)

        # 未参加のゲストユーザーでアクセス
        guest_user = create(:user)
        create(:profile, user: guest_user)
        sign_in guest_user

        # RoomMembership が増えないこと
        expect {
          get share_path(share_link.token)
        }.not_to change(RoomMembership, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ロック中の部屋に既存メンバーがアクセスした場合" do
      it "部屋ページへリダイレクトする" do
        # ロック中の部屋にメンバーを準備
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        locked_room = create(:room, issuer_profile: room_owner_profile, locked: true)
        share_link = create(:share_link, room: locked_room, expires_at: 1.year.from_now)

        # 既存メンバーとして参加済みにする
        member_user = create(:user)
        member_profile = create(:profile, user: member_user)
        create(:room_membership, room: locked_room, profile: member_profile)
        sign_in member_user

        # アクション: 有効な入場券で開く
        get share_path(share_link.token)

        # アサーション: 地図は出さず、部屋へ案内する
        expect(response).to redirect_to(room_path(locked_room))
      end
    end

    context "ロック中の部屋にオーナーがアクセスした場合" do
      it "部屋ページへリダイレクトする" do
        # ロック中の部屋を作成したオーナーでアクセス
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        locked_room = create(:room, issuer_profile: room_owner_profile, locked: true)
        share_link = create(:share_link, room: locked_room, expires_at: 1.year.from_now)
        create(:room_membership, room: locked_room, profile: room_owner_profile)
        sign_in room_owner

        # アクション: 有効な入場券で開く
        get share_path(share_link.token)

        # アサーション: 地図は出さず、部屋へ案内する
        expect(response).to redirect_to(room_path(locked_room))
      end
    end

    context "期限切れリンクに非メンバーがアクセスした場合" do
      it "410 Gone を返す" do
        # 期限切れの共有リンクを準備
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        room = create(:room, issuer_profile: room_owner_profile)
        expired_link = create(:share_link, room: room, expires_at: 1.hour.ago)

        # 未参加のゲストユーザーでアクセス
        guest_user = create(:user)
        create(:profile, user: guest_user)
        sign_in guest_user

        get share_path(expired_link.token)

        # 期限切れ+非メンバー → 410 Gone
        expect(response).to have_http_status(:gone)
      end
    end

    context "ロックされていない部屋に未参加ユーザーがアクセスした場合" do
      it "部屋ページへリダイレクトし、RoomMembership は増えない" do
        # 公開中の部屋と共有リンクを準備
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        unlocked_room = create(:room, issuer_profile: room_owner_profile, locked: false)
        share_link = create(:share_link, room: unlocked_room, expires_at: 1.year.from_now)

        # 未参加ゲストユーザーでアクセス
        guest_user = create(:user)
        create(:profile, user: guest_user)
        sign_in guest_user

        # アクション: 有効な入場券で開く
        expect {
          get share_path(share_link.token)
        }.not_to change(RoomMembership, :count)

        # アサーション: 参加せず、部屋へ案内する
        expect(response).to redirect_to(room_path(unlocked_room))
      end

      it "recent_room_token Cookieにトークンがセットされる" do
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        unlocked_room = create(:room, issuer_profile: room_owner_profile, locked: false)
        share_link = create(:share_link, room: unlocked_room, expires_at: 1.year.from_now, token: "cookietoken")

        guest_user = create(:user)
        create(:profile, user: guest_user)
        sign_in guest_user

        get share_path(share_link.token)

        expect(response.cookies["recent_room_token"]).to eq("cookietoken")
      end
    end
  end
end
