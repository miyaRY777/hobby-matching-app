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
      it "通常通りページが表示される" do
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

        # ページが表示されること
        get share_path(share_link.token)

        expect(response).to have_http_status(:ok)
      end
    end

    context "ロック中の部屋にオーナーがアクセスした場合" do
      it "通常通りページが表示される" do
        # ロック中の部屋を作成したオーナーでアクセス
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        locked_room = create(:room, issuer_profile: room_owner_profile, locked: true)
        share_link = create(:share_link, room: locked_room, expires_at: 1.year.from_now)
        create(:room_membership, room: locked_room, profile: room_owner_profile)
        sign_in room_owner

        # ページが表示されること
        get share_path(share_link.token)

        expect(response).to have_http_status(:ok)
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
      it "RoomMembership が作成される" do
        # 公開中の部屋と共有リンクを準備
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        unlocked_room = create(:room, issuer_profile: room_owner_profile, locked: false)
        share_link = create(:share_link, room: unlocked_room, expires_at: 1.year.from_now)

        # 未参加ゲストユーザーでアクセス
        guest_user = create(:user)
        create(:profile, user: guest_user)
        sign_in guest_user

        # RoomMembership が1件増えること
        expect {
          get share_path(share_link.token)
        }.to change(RoomMembership, :count).by(1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
