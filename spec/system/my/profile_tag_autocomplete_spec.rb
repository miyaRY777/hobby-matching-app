require "rails_helper"

RSpec.describe "タグ入力チップUI", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:profile) { create(:profile, user:) }

  before do
    login_as(user, scope: :user)
    visit edit_my_profile_path
  end

  describe "タグの追加" do
    it "Enterキーで新規タグをチップとして追加できる" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='tag-input']").send_keys(:return)

      expect(page).to have_css("[data-testid='chip']", text: "ゲーム")
    end

    it "同一タグは重複追加できない" do
      2.times do
        fill_in "tag-input", with: "ゲーム"
        find("[data-testid='tag-input']").send_keys(:return)
      end

      expect(page).to have_css("[data-testid='chip']", text: "ゲーム", count: 1)
    end

    it "10個追加するとinputが無効化される" do
      10.times do |i|
        fill_in "tag-input", with: "タグ#{i}"
        find("[data-testid='tag-input']").send_keys(:return)
      end

      expect(page).to have_css("[data-testid='chip']", count: 10)
      expect(find("[data-testid='tag-input']")[:disabled]).to eq("true")
    end
  end

  describe "タグの削除" do
    it "×ボタンでチップを削除できる" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='tag-input']").send_keys(:return)
      expect(page).to have_css("[data-testid='chip']", text: "ゲーム")

      find("[data-testid='chip']", text: "ゲーム").find("button").click

      expect(page).not_to have_css("[data-testid='chip']", text: "ゲーム")
    end
  end

  describe "オートコンプリート" do
    before { create(:hobby, name: "ゲーム") }

    it "2文字以上で候補が表示される" do
      fill_in "tag-input", with: "ゲー"

      expect(page).to have_css("[data-testid='autocomplete-item']", text: "ゲーム")
    end

    it "候補を選択するとチップになり入力欄がクリアされる" do
      fill_in "tag-input", with: "ゲー"
      find("[data-testid='autocomplete-item']", text: "ゲーム").click

      expect(page).to have_css("[data-testid='chip']", text: "ゲーム")
      expect(find("[data-testid='tag-input']").value).to eq("")
    end

    it "1文字では候補が表示されない" do
      fill_in "tag-input", with: "ゲ"

      expect(page).not_to have_css("[data-testid='autocomplete-item']")
    end
  end

  describe "フォーム送信" do
    it "チップのタグが保存される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='tag-input']").send_keys(:return)
      click_button "更新する"

      expect(page).to have_content("ゲーム")
      expect(profile.reload.hobbies.pluck(:name)).to include("ゲーム")
    end
  end

  describe "Turbo再表示時のチップ復元" do
    it "バリデーションエラー後もチップが復元される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='tag-input']").send_keys(:return)

      # bioを空にしてバリデーションエラーを発生させる
      fill_in "profile[bio]", with: ""
      click_button "更新する"

      expect(page).to have_css("[data-testid='chip']", text: "ゲーム")
    end
  end
end
