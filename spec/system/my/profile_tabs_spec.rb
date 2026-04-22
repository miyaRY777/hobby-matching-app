require "rails_helper"

RSpec.describe "プロフィール編集タブ", type: :system, js: true do
  # プロフィール作成済みのユーザーを用意
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # ログインしてプロフィール編集画面へ
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
  end

  describe "自己紹介タブ" do
    it "初期表示では自己紹介パネルが表示されている" do
      # デフォルトで自己紹介タブがアクティブなので bio が見える
      expect(page).to have_css("textarea[id='profile_bio']", visible: true)
    end

    it "アクティブな自己紹介タブを再クリックしてもbioパネルが消えない" do
      # 自己紹介タブボタンを取得（最初のタブ）
      bio_tab = find("[data-tabs-target='tab']", match: :first)

      # すでにアクティブな自己紹介タブを再クリック
      bio_tab.click

      # bio textarea が visible のまま
      expect(page).to have_css("textarea[id='profile_bio']", visible: true)
    end
  end

  describe "タグタブ" do
    it "タグタブを2回クリックしてもタグパネルが消えない" do
      # タグタブ（2番目のタブ）をクリックしてアクティブにする
      tag_tab = all("[data-tabs-target='tab']")[1]
      tag_tab.click

      # タグ入力欄が表示されることを確認
      expect(page).to have_css("[data-testid='tag-input']", visible: true)

      # もう一度タグタブをクリック
      tag_tab.click

      # タグ入力欄が消えない
      expect(page).to have_css("[data-testid='tag-input']", visible: true)
    end
  end
end
