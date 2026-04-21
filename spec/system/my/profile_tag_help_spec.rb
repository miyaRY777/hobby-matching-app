require "rails_helper"

RSpec.describe "趣味タグ ヘルプ導線", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"
  end

  it "「親タグとは？」ボタンが表示されている" do
    expect(page).to have_css("[data-testid='tag-help-toggle']")
    expect(page).to have_text("親タグとは？")
  end

  it "「親タグとは？」をクリックするとヘルプが展開される" do
    expect(page).not_to have_css("[data-testid='tag-help-content']", visible: true)

    find("[data-testid='tag-help-toggle']").click

    expect(page).to have_css("[data-testid='tag-help-content']", visible: true)
    expect(page).to have_text("親タグとは？")
    expect(page).to have_text("マインドマップのイメージ")
    expect(page).to have_css("img[alt='部屋名を起点に親タグと子タグが枝分かれするマインドマップの例']")
    expect(page).to have_text("わからない")
  end

  it "展開後に「閉じる」をクリックするとヘルプが折りたたまれる" do
    find("[data-testid='tag-help-toggle']").click
    expect(page).to have_css("[data-testid='tag-help-content']", visible: true)

    find("[data-testid='tag-help-toggle']").click

    expect(page).to have_css("[data-testid='tag-help-content']", visible: false)
  end
end
