require "rails_helper"

RSpec.describe "shares/show.html.erb", type: :view do
  let(:issuer_profile) { create(:profile) }
  let(:room) { create(:room, issuer_profile:, label: "もくもく部屋", room_type: :study, locked:) }
  let!(:membership) { create(:room_membership, room:, profile: issuer_profile) }

  before do
    assign(:room, room)
    assign(:viewer_profile, viewer_profile)
    assign(:memberships, room.room_memberships.includes(:profile))
    assign(:jsmind_data, { meta: { name: room.label }, format: "node_tree", data: { id: "root", topic: room.label } })
  end

  context "プロフィール未登録の閲覧者の場合" do
    let(:locked) { false }
    let(:viewer_profile) { nil }

    it "プロフィール作成導線と公開中の表示を描画する" do
      render

      expect(rendered).to include("プロフィール未登録です")
      expect(rendered).to include("プロフィール作成")
      expect(rendered).to include("もくもく部屋")
      expect(rendered).to include("勉強")
      expect(rendered).to include("公開中")
    end
  end

  context "プロフィール登録済みで部屋がロック中の場合" do
    let(:locked) { true }
    let(:viewer_profile) { create(:profile) }

    it "ロック中メッセージを描画する" do
      render

      expect(rendered).to include("ロック中")
      expect(rendered).to include("この部屋は現在ロック中です。新しいメンバーは参加できません。")
      expect(rendered).not_to include("プロフィール未登録です")
    end
  end
end
