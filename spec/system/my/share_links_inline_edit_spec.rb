require "rails_helper"

RSpec.describe "My::ShareLinks inline edit", type: :system, js: true do
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

    within("#room_#{room.id}") do
      click_on "編集"

      # フォームが出るのを待つ（ここ重要）
      expect(page).to have_field("部屋名")

      fill_in "部屋名", with: "グループ1"
      click_button "更新"

      # Turbo Streamで行が差し替わるのを待つ
      expect(page).to have_content("グループ1")
    end

    # 画面の更新完了後にDBを確認
    expect(room.reload.label).to eq("グループ1")
  end
end
