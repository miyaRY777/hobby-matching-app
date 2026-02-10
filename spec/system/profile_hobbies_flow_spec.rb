require "rails_helper"

RSpec.describe "趣味(タグ)登録の一連の流れ", type: :system do
  it "ログインして、プロフィール編集でタグを更新し、詳細に表示させる" do
    user = create(:user)
    create(:profile, user: user)

    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "ログイン"

    profile = user.profile
    visit edit_my_profile_path

    fill_in "タグ", with: "rails, ruby"
    click_button "更新する"

    expect(page).to have_content("rails")
    expect(page).to have_content("ruby")
  end
end
