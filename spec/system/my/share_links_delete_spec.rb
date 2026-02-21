require "rails_helper"

RSpec.describe "My::ShareLinks delete", type: :system, js: true do
  it "部屋をその場で削除できる" do
    user = create(:user)
    profile = create(:profile, user: user)

    room = create(:room, issuer_profile: profile, label: "部屋A")
    create(:share_link, room: room, expires_at: 1.hour.from_now)

    login_as(user, scope: :user)
    visit my_share_links_path

    # まず表示されている
    expect(page).to have_selector("#room_#{room.id}")

    # Turboでその場削除（confirmは accept_confirm で）
    accept_confirm do
      within("#room_#{room.id}") do
        click_on "削除"
      end
    end

    # 消えた（ここだけ見る）
    expect(page).not_to have_selector("#room_#{room.id}")
  end
end