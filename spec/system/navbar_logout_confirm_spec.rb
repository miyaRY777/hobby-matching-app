require "rails_helper"

RSpec.describe "ナビゲーションバーのログアウト", type: :system, js: true do
  it "確認ダイアログをキャンセルするとログアウトしない" do
    user = create(:user)
    create(:profile, user:)

    login_as user, scope: :user
    visit profiles_path

    dismiss_confirm("ログアウトしますか？") do
      click_button "ログアウト"
    end

    expect(page).to have_current_path(profiles_path)
    expect(page).to have_button("ログアウト")
  end
end
