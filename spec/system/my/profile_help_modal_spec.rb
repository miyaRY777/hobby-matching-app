require "rails_helper"

RSpec.describe "プロフィールヘルプモーダル", type: :system, js: true do
  describe "プロフィール作成画面" do
    # プロフィール未作成のユーザーを用意
    let(:current_user) { create(:user) }

    before do
      # ログインしてプロフィール作成画面へ
      login_as(current_user, scope: :user)
      visit new_my_profile_path
    end

    it "？ボタンが表示されている" do
      # aria-label でボタンを特定して存在確認
      expect(page).to have_css("button[aria-label='プロフィール作成のヘルプを開く']")
    end

    it "？ボタンをクリックするとヘルプモーダルが開く" do
      # ？ボタンをクリック
      find("button[aria-label='プロフィール作成のヘルプを開く']").click

      # hidden が外れてモーダルが visible になること、ヘルプタイトルが表示されること
      expect(page).to have_css("[data-testid='help-modal']", visible: true)
      expect(page).to have_text("プロフィール作成のヘルプ")
    end

    it "×ボタンをクリックするとモーダルが閉じる" do
      # モーダルを開く
      find("button[aria-label='プロフィール作成のヘルプを開く']").click

      # ×ボタンをクリック
      find("[data-testid='help-modal-close']").click

      # hidden クラスが戻ってモーダルが非表示になること
      expect(page).to have_css("[data-testid='help-modal']", visible: false)
    end

    it "バックドロップをクリックするとモーダルが閉じる" do
      # モーダルを開く
      find("button[aria-label='プロフィール作成のヘルプを開く']").click

      # バックドロップをJSで直接クリック（パネルが中心を覆うため execute_script で発火）
      find("[data-testid='help-modal-backdrop']").execute_script("this.click()")

      # モーダルが非表示になること
      expect(page).to have_css("[data-testid='help-modal']", visible: false)
    end
  end

  describe "プロフィール編集画面" do
    # プロフィール作成済みのユーザーを用意
    let(:current_user) { create(:user) }
    let!(:current_profile) { create(:profile, user: current_user) }

    before do
      # ログインしてプロフィール編集画面へ
      login_as(current_user, scope: :user)
      visit edit_my_profile_path
    end

    it "？ボタンが表示されている" do
      # aria-label でボタンを特定して存在確認
      expect(page).to have_css("button[aria-label='プロフィール編集のヘルプを開く']")
    end

    it "？ボタンをクリックするとヘルプモーダルが開く" do
      # ？ボタンをクリック
      find("button[aria-label='プロフィール編集のヘルプを開く']").click

      # モーダルが visible になり、編集画面専用タイトルが表示されること
      expect(page).to have_css("[data-testid='help-modal']", visible: true)
      expect(page).to have_text("プロフィール編集のヘルプ")
    end

    it "×ボタンをクリックするとモーダルが閉じる" do
      # モーダルを開く
      find("button[aria-label='プロフィール編集のヘルプを開く']").click

      # ×ボタンをクリック
      find("[data-testid='help-modal-close']").click

      # モーダルが非表示になること
      expect(page).to have_css("[data-testid='help-modal']", visible: false)
    end
  end
end
