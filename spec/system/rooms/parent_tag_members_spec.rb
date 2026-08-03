require "rails_helper"

RSpec.describe "親タグ関連ユーザー表示", type: :system, js: true do
  let(:viewer_user) { create(:user, nickname: "viewer") }
  let(:viewer_profile) { create(:profile, user: viewer_user) }
  let(:room) { create(:room, issuer_profile: viewer_profile, room_type: :chat) }
  let(:share_link) { create(:share_link, room:, expires_at: 1.hour.from_now) }
  let(:parent_tag) { create(:parent_tag, name: "ゲーム", room_type: :chat) }
  let(:hobby) { create(:hobby, name: "Among Us") }
  let!(:first_profile) { create_member("demo_user1") }
  let!(:second_profile) { create_member("demo_user2") }

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:hobby_parent_tag, hobby:, parent_tag:)
    create(:profile_hobby, profile: first_profile, hobby:, description: "first description")
    create(:profile_hobby, profile: second_profile, hobby:, description: "second description")
    login_as(viewer_user, scope: :user)
    visit share_path(share_link.token)
  end

  it "親タグ選択とページ送りで関連ユーザーを1人ずつ表示する" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_text("ゲームに関連するユーザー 2人")
      expect(page).to have_text("demo_user1")
      expect(page).to have_no_text("demo_user2")
      click_link "次へ ›"
      expect(page).to have_text("demo_user2")
      expect(page).to have_no_text("demo_user1")
    end

    expect(page).to have_css("#jsmind_container")
  end

  it "個別ユーザー選択で従来の1人表示へ切り替える" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click
    expect(page).to have_text("ゲームに関連するユーザー 2人")

    find("jmnode[nodeid='p_#{second_profile.id}_pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_text("demo_user2")
      expect(page).to have_no_text("ゲームに関連するユーザー 2人")
    end
  end

  it "ページ移動後のカードでも趣味説明を開ける" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      click_link "次へ ›"
      expect(page).to have_text("demo_user2")
    end

    within("turbo-frame#member_detail") do
      click_button "Among Us"
      expect(page).to have_text("second description")
    end
  end

  def create_member(nickname)
    profile = create(:profile, user: create(:user, nickname:))
    create(:room_membership, room:, profile:)
    profile
  end
end
