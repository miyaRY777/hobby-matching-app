require "rails_helper"

# ナビバーの直近参加部屋リンクの表示・非表示を確認すること
RSpec.describe "Navbar", type: :request do
  describe "直近の参加部屋リンク" do
    # 参加部屋ありの場合のテスト
    context "参加部屋がある場合" do
      it "直近部屋名のリンクがナビに表示される" do
        # セットアップ：ユーザー・プロフィール・部屋・share_linkを用意
        current_user = create(:user)
        current_profile = create(:profile, user: current_user)
        recent_room = create(:room, label: "直近の部屋")
        create(:room_membership, profile: current_profile, room: recent_room)
        create(:share_link, room: recent_room, expires_at: nil, token: "nav_tok")
        sign_in current_user

        # アクション
        get profiles_path

        # アサーション：「部屋に戻る」ボタンとshare_pathリンクがナビに含まれること
        expect(response.body).to include("部屋に戻る")
        expect(response.body).to include(share_path("nav_tok"))
      end
    end

    # 参加部屋なしの場合のテスト
    context "参加部屋がない場合" do
      it "直近部屋リンクがナビに表示されない" do
        # セットアップ：プロフィールあり・部屋への参加なし
        current_user = create(:user)
        create(:profile, user: current_user)
        sign_in current_user

        # アクション
        get profiles_path

        # アサーション：share_pathリンクがナビに含まれないこと
        expect(response.body).not_to include("/share/")
      end
    end

    # 未ログインの場合のテスト
    context "未ログインの場合" do
      it "直近部屋リンクがナビに表示されない" do
        # アクション（未ログイン）
        get profiles_path

        # アサーション：share_pathリンクがナビに含まれないこと
        expect(response.body).not_to include("/share/")
      end
    end
  end
end
