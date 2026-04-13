require "rails_helper"

RSpec.describe "趣味(タグ)登録の一連の流れ", type: :system, js: true do
  it "ログインして、プロフィール編集でタグを更新し、詳細に表示させる" do
    user = create(:user)
    create(:profile, user: user)

    login_as(user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"

    # chip が DOM に追加されるまで待ってから次のタグを入力する（JS タイミング対策）
    fill_in "tag-input", with: "rails"
    find("[data-testid='tag-input']").send_keys(:return)
    expect(page).to have_css("[data-testid='chip']", text: "rails")

    fill_in "tag-input", with: "ruby"
    find("[data-testid='tag-input']").send_keys(:return)
    expect(page).to have_css("[data-testid='chip']", text: "ruby")

    click_button "更新する"

    expect(page).to have_content("rails")
    expect(page).to have_content("ruby")
  end
end
