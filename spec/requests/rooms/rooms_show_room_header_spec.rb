require "rails_helper"

RSpec.describe "Rooms#show header", type: :request do
  let(:issuer_user) { create(:user) }
  let(:issuer_profile) { create(:profile, user: issuer_user) }

  context "studyタイプ・公開中の部屋" do
    let(:room) { create(:room, issuer_profile: issuer_profile, room_type: :study, locked: false) }

    before do
      create(:room_membership, room: room, profile: issuer_profile)
      sign_in issuer_user
      get room_path(room)
    end

    it "room_typeが日本語で表示される" do
      expect(response.body).to include("勉強")
    end

    it "公開中バッジが表示される" do
      expect(response.body).to include("公開中")
    end

    it "参加人数が表示される" do
      expect(response.body).to include("1人")
    end

    it "公開中の状態案内が表示される" do
      expect(response.body).to include("この部屋は公開中です")
    end

    it "更新ボタンが表示される" do
      expect(response.body).to include("更新")
    end
  end

  context "非公開の部屋" do
    let(:room) { create(:room, issuer_profile: issuer_profile, locked: true) }

    before do
      sign_in issuer_user
      get room_path(room)
    end

    it "非公開バッジが表示される" do
      expect(response.body).to include("非公開")
      expect(response.body).not_to include("ロック中")
    end

    it "非公開の状態案内が表示される" do
      expect(response.body).to include("この部屋は非公開です。新しいメンバーは参加できません。")
    end
  end
end
