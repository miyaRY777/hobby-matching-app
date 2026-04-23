require "rails_helper"

RSpec.describe "mypage/rooms テーブル表示", type: :system, js: true do
  # セットアップ
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:owner_profile) { create(:profile) }
  let!(:own_room) { create(:room, issuer_profile: current_profile, label: "管理中の部屋", locked: false) }
  let!(:other_room) { create(:room, issuer_profile: owner_profile, label: "参加中の部屋") }
  let!(:own_membership) { create(:room_membership, room: own_room, profile: current_profile) }
  let!(:joined_membership) { create(:room_membership, room: other_room, profile: current_profile) }

  before do
    create(:share_link, room: own_room)
    login_as(current_user, scope: :user)
    visit mypage_rooms_path
  end

  # アサーション：テーブルが存在する
  it "テーブルが表示される" do
    expect(page).to have_css("table")
  end

  # アサーション：管理中の部屋がテーブルのセルに表示される
  it "管理中の部屋がテーブルに表示される" do
    expect(page).to have_css("table td", text: "管理中の部屋")
  end

  # アサーション：参加中の部屋が同じテーブルのセルに表示される
  it "参加中の部屋が同じテーブルに表示される" do
    expect(page).to have_css("table td", text: "参加中の部屋")
  end

  # アサーション：管理中バッジが管理者行に表示される
  it "管理中バッジが表示される" do
    within("tr##{ActionView::RecordIdentifier.dom_id(own_room)}") do
      expect(page).to have_text("管理中")
    end
  end

  # アサーション：参加中バッジが参加者行に表示される
  it "参加中バッジが表示される" do
    within("tr##{ActionView::RecordIdentifier.dom_id(joined_membership)}") do
      expect(page).to have_text("参加中")
    end
  end

  # アサーション：管理者行に編集リンクがある
  it "管理者行に編集リンクがある" do
    within("tr##{ActionView::RecordIdentifier.dom_id(own_room)}") do
      expect(page).to have_link("編集")
    end
  end

  # アサーション：参加者行に退出ボタンがある
  it "参加者行に退出ボタンがある" do
    within("tr##{ActionView::RecordIdentifier.dom_id(joined_membership)}") do
      expect(page).to have_button("退出")
    end
  end
end
