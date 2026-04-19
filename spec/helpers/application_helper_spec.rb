require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#avatar_image_tag" do
    context "アバターが未設定の場合" do
      let(:user) { create(:user) }

      it "デフォルトアイコンのimgタグを返す" do
        result = helper.avatar_image_tag(user)

        expect(result).to include("<img")
        expect(result).to include("svg")
        expect(result).to include('data-testid="avatar"')
      end
    end

    context "アバターが設定されている場合" do
      let(:user) { create(:user) }

      before do
        user.avatar.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/valid_avatar.jpg")),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
      end

      it "アバター画像のimgタグを返す" do
        result = helper.avatar_image_tag(user)

        expect(result).to include("<img")
        expect(result).not_to include("svg")
        expect(result).to include('data-testid="avatar"')
      end
    end
  end

  describe "#recent_room_nav_info" do
    # 未ログインの場合のテスト
    context "未ログインの場合" do
      it "nilを返す" do
        # アクション＋アサーション：nilユーザーを渡すとnilを返すこと
        expect(helper.recent_room_nav_info(nil)).to be_nil
      end
    end

    # プロフィールなしの場合のテスト
    context "ログイン済みでプロフィールがない場合" do
      let(:current_user) { create(:user) }

      it "nilを返す" do
        # アクション＋アサーション：プロフィールなしユーザーを渡すとnilを返すこと
        expect(helper.recent_room_nav_info(current_user)).to be_nil
      end
    end

    # 参加部屋なしの場合のテスト
    context "ログイン済み・プロフィールあり・参加部屋なしの場合" do
      let(:current_user) { create(:user) }

      before do
        # セットアップ：プロフィールあり・部屋への参加なし
        create(:profile, user: current_user)
      end

      it "nilを返す" do
        # アクション＋アサーション：参加部屋がないのでnilを返すこと
        expect(helper.recent_room_nav_info(current_user)).to be_nil
      end
    end

    # share_linkありの場合のテスト
    context "参加部屋あり・share_linkがある場合" do
      let(:current_user) { create(:user) }
      let(:current_profile) { create(:profile, user: current_user) }
      let(:recent_room) { create(:room, label: "直近テスト部屋") }

      before do
        # セットアップ：部屋・membership・share_linkを用意
        create(:room_membership, profile: current_profile, room: recent_room)
        create(:share_link, room: recent_room, expires_at: nil, token: "tok123")
      end

      it "share_pathとroom labelを返す" do
        # アクション
        result = helper.recent_room_nav_info(current_user)

        # アサーション：パスとラベルが正しいこと
        expect(result[:path]).to eq(share_path("tok123"))
        expect(result[:label]).to eq("直近テスト部屋")
      end
    end

    # share_linkがnilの場合のテスト（edge case）
    context "参加部屋あり・share_linkがnilの場合" do
      let(:current_user) { create(:user) }
      let(:current_profile) { create(:profile, user: current_user) }
      let(:room_without_link) { create(:room, label: "share_linkなし部屋") }

      before do
        # セットアップ：share_linkを持たない部屋に参加
        create(:room_membership, profile: current_profile, room: room_without_link)
      end

      it "mypage_rooms_pathとroom labelを返す" do
        # アクション
        result = helper.recent_room_nav_info(current_user)

        # アサーション：フォールバックパスとラベルが正しいこと
        expect(result[:path]).to eq(mypage_rooms_path)
        expect(result[:label]).to eq("share_linkなし部屋")
      end
    end
  end
end
