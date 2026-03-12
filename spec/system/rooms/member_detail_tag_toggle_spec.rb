require "rails_helper"

RSpec.describe "部屋メンバー詳細タグ切り替え", type: :system, js: true do
  let(:viewer_user) { create(:user) }
  let(:member_user) { create(:user) }
  let!(:viewer_profile) { create(:profile, user: viewer_user) }
  let!(:member_profile) { create(:profile, user: member_user) }
  let!(:room) { create(:room, issuer_profile: viewer_profile) }
  let!(:hobby) { create(:hobby, name: "ゲーム") }

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:room_membership, room:, profile: member_profile)
    create(:profile_hobby, profile: member_profile, hobby:, description: "毎日やってます")
    login_as(viewer_user, scope: :user)
    visit room_member_path(room_id: room.id, id: member_profile.id)
  end

  it "「プロフィール詳細を見る」リンクが表示されない" do
    expect(page).not_to have_link("プロフィール詳細を見る")
  end

  it "タグをクリックすると説明文が表示される" do
    expect(page).not_to have_text("毎日やってます")
    find("[data-testid='toggle-tag']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
  end

  it "説明文が未入力の場合は「未入力」と表示される" do
    hobby2 = create(:hobby, name: "釣り")
    create(:profile_hobby, profile: member_profile, hobby: hobby2, description: nil)
    visit room_member_path(room_id: room.id, id: member_profile.id)
    find("[data-testid='toggle-tag']", text: "釣り").click
    expect(page).to have_text("未入力")
  end
end
