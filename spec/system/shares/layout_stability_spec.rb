require "rails_helper"

RSpec.describe "部屋ページの横位置", type: :system, js: true do
  let(:viewer_user) { create(:user, nickname: "閲覧者") }
  let(:viewer_profile) { create(:profile, user: viewer_user) }
  let(:short_user) { create(:user, nickname: "短文ユーザー") }
  let(:short_profile) { create(:profile, user: short_user, bio: "短い自己紹介") }
  let(:long_user) { create(:user, nickname: "長文ユーザー") }
  let(:long_profile) { create(:profile, user: long_user, bio: "長い自己紹介" * 30) }
  let(:tag_user) { create(:user, nickname: "タグ切替ユーザー") }
  let(:tag_profile) { create(:profile, user: tag_user, bio: "タグ切り替え確認用") }
  let(:room) { create(:room, issuer_profile: viewer_profile, room_type: :chat) }
  let(:parent_tag) { create(:parent_tag, room_type: :chat) }
  let(:short_hobby) { create(:hobby, name: "短文タグ") }
  let(:long_hobby) { create(:hobby, name: "長文タグ") }

  before do
    [ viewer_profile, short_profile, long_profile, tag_profile ].each do |profile|
      create(:room_membership, room:, profile:)
    end

    create(:hobby_parent_tag, hobby: short_hobby, parent_tag:)
    create(:hobby_parent_tag, hobby: long_hobby, parent_tag:)
    create(:profile_hobby, profile: short_profile, hobby: short_hobby, description: "短い説明")
    create(:profile_hobby, profile: long_profile, hobby: short_hobby, description: "短い説明")
    create(:profile_hobby, profile: tag_profile, hobby: short_hobby, description: "短い説明")
    create(:profile_hobby, profile: tag_profile, hobby: long_hobby, description: "長い説明" * 50)
    8.times do |index|
      hobby = create(:hobby, name: "追加タグ#{index + 1}")
      create(:hobby_parent_tag, hobby:, parent_tag:)
      create(:profile_hobby, profile: long_profile, hobby:, description: "追加説明")
    end

    login_as(viewer_user, scope: :user)
    visit room_path(room)
  end

  it "ユーザーを切り替えても部屋ページの横幅と左位置が変わらない" do
    select_member("短文ユーザー")
    before_switch = share_container_rect

    select_member("長文ユーザー")
    after_switch = share_container_rect

    expect(after_switch["width"]).to be_within(1).of(before_switch["width"])
    expect(after_switch["left"]).to be_within(1).of(before_switch["left"])
  end

  it "タグを切り替えても部屋ページの横幅と左位置が変わらない" do
    select_member("タグ切替ユーザー")

    within("turbo-frame#member_detail") do
      click_button "短文タグ"
      expect(page).to have_text("短い説明")
    end
    before_switch = share_container_rect

    within("turbo-frame#member_detail") do
      click_button "長文タグ"
      expect(page).to have_text("長い説明")
    end
    after_switch = share_container_rect

    expect(after_switch["width"]).to be_within(1).of(before_switch["width"])
    expect(after_switch["left"]).to be_within(1).of(before_switch["left"])
  end

  private

  def select_member(nickname)
    find("jmnode", text: nickname, exact_text: true).click
    within("turbo-frame#member_detail") do
      expect(page).to have_text(nickname)
    end
  end

  def share_container_rect
    page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const rect = document.querySelector("main > div.max-w-7xl").getBoundingClientRect()
        return { left: rect.left, width: rect.width }
      })()
    JAVASCRIPT
  end
end
