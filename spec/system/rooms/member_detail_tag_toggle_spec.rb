require "rails_helper"

RSpec.describe "部屋メンバー詳細タブ切り替え", type: :system, js: true do
  let(:viewer_user) { create(:user) }
  let(:member_user) { create(:user) }
  let!(:viewer_profile) { create(:profile, user: viewer_user) }
  let!(:member_profile) { create(:profile, user: member_user, bio: "メンバー自己紹介です") }
  let!(:game_parent_tag) { create(:parent_tag, room_type: :game) }
  let!(:room) { create(:room, issuer_profile: viewer_profile, room_type: :game) }
  let!(:hobby) do
    hobby = create(:hobby, name: "ゲーム")
    create(:hobby_parent_tag, hobby:, parent_tag: game_parent_tag)
    hobby
  end

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:room_membership, room:, profile: member_profile)
    create(:profile_hobby, profile: member_profile, hobby:, description: "毎日やってます")
    login_as(viewer_user, scope: :user)
    visit room_member_path(room_id: room.id, id: member_profile.id)
  end

  it "ページを開くと説明エリアは非表示" do
    expect(page).to have_no_css("[data-tabs-target='panel']:not(.hidden)")
  end

  it "タブをクリックすると説明文が表示される" do
    find("[data-tabs-target='tab']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
  end

  it "「ひとこと」タブをクリックすると自己紹介が表示される" do
    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_text("メンバー自己紹介です")
    expect(page).to have_css("[data-tabs-target='panel'].hidden", text: "毎日やってます", visible: false)
  end

  it "選択中の趣味タブを再クリックすると説明エリアが閉じる" do
    find("[data-tabs-target='tab']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")

    find("[data-tabs-target='tab']", text: "ゲーム").click
    expect(page).to have_no_css("[data-tabs-target='panel']:not(.hidden)")
  end

  it "選択中の「ひとこと」タブを再クリックすると説明エリアが閉じる" do
    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_text("メンバー自己紹介です")

    find("[data-tabs-target='tab']", text: "ひとこと").click
    expect(page).to have_no_css("[data-tabs-target='panel']:not(.hidden)")
  end

  context "説明文が未入力のタブがある場合" do
    let!(:hobby2) do
      hobby = create(:hobby, name: "釣り")
      create(:hobby_parent_tag, hobby:, parent_tag: game_parent_tag)
      hobby
    end

    before do
      create(:profile_hobby, profile: member_profile, hobby: hobby2, description: nil)
      visit room_member_path(room_id: room.id, id: member_profile.id)
    end

    it "タブをクリックすると「未入力」と表示される" do
      find("[data-tabs-target='tab']", text: "釣り").click
      expect(page).to have_text("未入力")
    end
  end
end
