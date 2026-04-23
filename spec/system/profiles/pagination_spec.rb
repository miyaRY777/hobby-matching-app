require "rails_helper"

RSpec.describe "プロフィール一覧ページネーション", type: :system do
  # セットアップ：9件のプロフィール（1ページ8件なので2ページ目が必要）
  let(:current_user) { create(:user) }

  before do
    create_list(:profile, 9)
    login_as(current_user, scope: :user)
    visit profiles_path
  end

  # アサーション：1ページ目は8件表示される
  it "1ページ目に8件のプロフィールカードが表示される" do
    expect(page).to have_css("[data-testid='profile-card']", count: 8)
  end

  # アサーション：「次へ」リンクが表示される
  it "次ページへのリンクが表示される" do
    expect(page).to have_link("次へ ›")
  end

  # アサーション：2ページ目に1件表示される
  it "2ページ目に残りの1件が表示される" do
    click_link "次へ ›"
    expect(page).to have_css("[data-testid='profile-card']", count: 1)
  end
end
