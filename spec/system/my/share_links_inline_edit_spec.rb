require "rails_helper"

RSpec.describe "My::ShareLinks inline edit", type: :system do
  it "部屋名をその場で編集・更新する" do
    # 発行者（=ログインユーザー）を用意
    user = create(:user)
    profile = create(:profile, user: user)

    # 発行者の部屋 + 共有リンク
    room = create(:room, issuer_profile: profile, label: "")
    create(:share_link, room: room, expires_at: 1.hour.from_now)

    # system spec のログイン（Devise sign_in ではなく Warden）
    login_as(user, scope: :user)

    visit my_share_links_path
    expect(page).to have_content("名無しの部屋")

    click_on "編集"
    expect(page).to have_current_path(my_share_links_path, ignore_query: true)
    fill_in "room_label", with: "グループ1"
    click_on "更新"

    expect(page).to have_content("グループ1")
  end
end
