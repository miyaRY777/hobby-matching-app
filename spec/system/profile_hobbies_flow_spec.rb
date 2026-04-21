require "rails_helper"

RSpec.describe "趣味(タグ)登録の一連の流れ", type: :system, js: true do
  it "ログインして、プロフィール編集でタグを更新し、詳細に表示させる" do
    user = create(:user)
    create(:profile, user: user)

    login_as(user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"

    fill_in "tag-input", with: "Ruby Rails"
    find("[data-testid='skip-parent-tag']").click
    expect(page).to have_text("Ruby Rails")

    fill_in "tag-input", with: "Ruby"
    find("[data-testid='skip-parent-tag']").click
    expect(page).to have_text("Ruby")

    click_button "更新する"

    expect(page).to have_content("Ruby Rails")
    expect(page).to have_content("Ruby")
  end
end
