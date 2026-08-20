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

  describe "#recent_room_nav_path" do
    # 責務: 見られる部屋なら room_path。410 の share_path には誘導しない。

    context "Cookieにトークンがある場合" do
      let(:current_user) { create(:user) }
      let(:owner_profile) { create(:profile) }
      let(:room) { create(:room, issuer_profile: owner_profile, locked: false) }

      before do
        create(:share_link, room:, token: "tok456", expires_at: 1.day.ago)
        allow(helper).to receive(:cookies).and_return({ recent_room_token: "tok456" }.with_indifferent_access)
      end

      it "期限切れでも公開なら room_path を返す" do
        expect(helper.recent_room_nav_path(current_user)).to eq(room_path(room))
      end

      it "非公開の未参加なら nil を返す" do
        room.update!(locked: true)
        create(:profile, user: current_user)

        expect(helper.recent_room_nav_path(current_user)).to be_nil
      end

      it "非公開でもメンバーなら room_path を返す" do
        room.update!(locked: true)
        current_profile = create(:profile, user: current_user)
        create(:room_membership, room:, profile: current_profile)

        expect(helper.recent_room_nav_path(current_user)).to eq(room_path(room))
      end
    end

    context "未ログインの場合" do
      it "nilを返す" do
        expect(helper.recent_room_nav_path(nil)).to be_nil
      end
    end

    context "ログイン済みでプロフィールがない場合" do
      let(:current_user) { create(:user) }

      it "Cookieがなければ nil を返す" do
        expect(helper.recent_room_nav_path(current_user)).to be_nil
      end
    end

    context "ログイン済み・プロフィールあり・参加部屋なしの場合" do
      let(:current_user) { create(:user) }

      before do
        create(:profile, user: current_user)
      end

      it "nilを返す" do
        expect(helper.recent_room_nav_path(current_user)).to be_nil
      end
    end

    context "参加部屋あり・share_linkがある場合" do
      let(:current_user) { create(:user) }
      let(:current_profile) { create(:profile, user: current_user) }
      let(:recent_room) { create(:room, label: "直近テスト部屋") }

      before do
        create(:room_membership, profile: current_profile, room: recent_room)
        create(:share_link, room: recent_room, expires_at: nil, token: "tok123")
      end

      it "room_path を返す" do
        expect(helper.recent_room_nav_path(current_user)).to eq(room_path(recent_room))
      end
    end

    context "参加部屋あり・share_linkがnilの場合" do
      let(:current_user) { create(:user) }
      let(:current_profile) { create(:profile, user: current_user) }
      let(:room_without_link) { create(:room, label: "share_linkなし部屋") }

      before do
        create(:room_membership, profile: current_profile, room: room_without_link)
      end

      it "room_path を返す" do
        expect(helper.recent_room_nav_path(current_user)).to eq(room_path(room_without_link))
      end
    end
  end
end
