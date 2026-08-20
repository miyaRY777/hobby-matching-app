require "rails_helper"

RSpec.describe "rooms/show.html.erb", type: :view do
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

  context "プロフィール登録済みで部屋が非公開の場合" do
    let(:locked) { true }
    let(:viewer_profile) { create(:profile) }

    it "非公開メッセージを描画する" do
      render

      expect(rendered).to include("非公開")
      expect(rendered).to include("この部屋は非公開です。新しいメンバーは参加できません。")
      expect(rendered).not_to include("ロック中")
      expect(rendered).not_to include("プロフィール未登録です")
    end
  end

  context "スクロール領域を描画する場合" do
    let(:locked) { false }
    let(:viewer_profile) { create(:profile) }

    it "部屋ページのスクロールバー用クラスを付与する" do
      render

      expect(rendered).to have_css("#jsmind_container.dark-scrollbar-host")
      expect(rendered).to have_css('[data-testid="member-detail-scroll-area"].dark-scrollbar')
    end
  end
end
