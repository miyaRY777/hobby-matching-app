require "rails_helper"

RSpec.describe "管理：未分類タグ ページネーション", type: :system do
  # セットアップ：未分類タグ11件（1ページ10件なので2ページ目が必要）
  let(:admin_user) { create(:user, :admin) }

  before do
    create_list(:hobby, 11)
    login_as(admin_user, scope: :user)
    visit admin_unclassified_hobbies_path
  end

  # アサーション：1ページ目に10件表示される
  it "1ページ目に10件のタグ行が表示される" do
    expect(page).to have_css("tbody tr", count: 10)
  end

  # アサーション：「次へ」リンクが表示される
  it "次ページへのリンクが表示される" do
    expect(page).to have_link("次へ ›")
  end

  # アサーション：2ページ目に1件表示される
  it "2ページ目に残りの1件が表示される" do
    click_link "次へ ›"
    expect(page).to have_css("tbody tr", count: 1)
  end
end
