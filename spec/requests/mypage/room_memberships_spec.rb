require "rails_helper"

RSpec.describe "Mypage::RoomMemberships", type: :request do
  # 退出機能のリクエストスペック
  describe "DELETE /mypage/room_memberships/:id" do
    context "ログインしている場合" do
      it "参加中の部屋から退出できる（turbo_stream）" do
        # 退出する本人（ログインユーザー）を作成
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)

        # 部屋の作成者を作成
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)

        # 作成者が作成した部屋を用意
        room_owners_room = create(:room, issuer_profile: room_owner_profile)

        # 本人がその部屋に参加している状態を作る
        own_membership = create(:room_membership, room: room_owners_room, profile: current_profile)

        # 本人でログイン
        sign_in current_user

        # Turbo Stream形式で退出リクエストを送る
        delete mypage_room_membership_path(own_membership),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        # 正常に処理されること
        expect(response).to have_http_status(:ok)

        # 参加情報が削除され、退出できていること
        expect(RoomMembership.exists?(own_membership.id)).to be false
      end

      it "自分が作成した部屋からは退出できない" do
        # 本人を作成
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)

        # 本人が作成した部屋を用意
        own_room = create(:room, issuer_profile: current_profile)

        # 作成者自身も membership を持っている状態を作る
        own_membership = create(:room_membership, room: own_room, profile: current_profile)

        # 本人でログイン
        sign_in current_user

        # 自分が作成した部屋に対して退出リクエストを送る
        delete mypage_room_membership_path(own_membership),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        # 退出は許可されず、部屋一覧へリダイレクトされること
        expect(response).to redirect_to(mypage_rooms_path)

        # membership は削除されず、そのまま残ること
        expect(RoomMembership.exists?(own_membership.id)).to be true
      end

      it "他のメンバーの membership を削除しようとすると部屋一覧にリダイレクトされる" do
        # ログインする本人を作成
        current_user = create(:user)
        create(:profile, user: current_user)

        # 他のメンバー（membership の持ち主）を作成
        other_member = create(:user)
        other_member_profile = create(:profile, user: other_member)

        # 部屋の作成者を別で作成
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)

        # 作成者が作成した部屋を用意
        room_owners_room = create(:room, issuer_profile: room_owner_profile)

        # 本人ではなく、他のメンバーが参加している membership を作成
        other_members_membership = create(:room_membership, room: room_owners_room, profile: other_member_profile)

        # 本人でログイン
        sign_in current_user

        # 他のメンバーの membership に対して削除リクエストを送る
        delete mypage_room_membership_path(other_members_membership)

        # 不正な削除は許可されず、部屋一覧へリダイレクトされること
        expect(response).to redirect_to(mypage_rooms_path)

        # 他のメンバーの membership は削除されないこと
        expect(RoomMembership.exists?(other_members_membership.id)).to be true
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        # 部屋の作成者と membership を用意
        room_owner = create(:user)
        room_owner_profile = create(:profile, user: room_owner)
        room_owners_room = create(:room, issuer_profile: room_owner_profile)
        room_owners_membership = create(:room_membership, room: room_owners_room, profile: room_owner_profile)

        # ログインせずに退出リクエストを送る
        delete mypage_room_membership_path(room_owners_membership)

        # 認証が必要なため、ログイン画面にリダイレクトされること
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
