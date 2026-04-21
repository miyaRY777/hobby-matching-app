require "rails_helper"

RSpec.describe "タグ入力チップUI", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # タグ操作はタグタブで行う
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"
  end

  describe "タグの追加" do
    it "新規タグを追加セクションから説明カードとして追加できる" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      expect(page).to have_text("ゲーム")
      expect(page).to have_css("[data-testid='description-toggle']", count: 1)
    end

    it "同一タグは重複追加できない" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      fill_in "tag-input", with: "ゲーム"
      expect(page).to have_text("ゲーム")
      expect(page).to have_css("[data-testid='description-toggle']", count: 1)
    end

    it "入力した表示名の大文字小文字を保ったままカードに追加できる" do
      fill_in "tag-input", with: "Ruby Rails"
      find("[data-testid='skip-parent-tag']").click

      expect(page).to have_css("[data-testid='tag-child-chip']", text: "Ruby Rails")
    end

    it "10個追加するとinputが無効化される" do
      10.times do |i|
        fill_in "tag-input", with: "タグ#{i}"
        find("[data-testid='skip-parent-tag']").click
      end

      expect(page).to have_css("[data-testid='description-toggle']", count: 10)
      expect(find("[data-testid='tag-input']")[:disabled]).to eq("true")
    end
  end

  describe "タグの削除" do
    it "カードの×ボタンでタグを削除できる" do
      # タグを追加してから削除する
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      expect(page).to have_text("ゲーム")

      find("button[aria-label='ゲームを削除']", visible: :all).click

      expect(page).not_to have_text("ゲーム")
    end
  end

  describe "オートコンプリート" do
    before { create(:hobby, name: "ゲーム") }

    it "2文字以上で候補が表示される" do
      fill_in "tag-input", with: "ゲー"

      expect(page).to have_css("[data-testid='autocomplete-item']", text: "ゲーム")
    end

    it "候補を選択するとカードになり入力欄がクリアされる" do
      fill_in "tag-input", with: "ゲー"
      find("[data-testid='autocomplete-item']", text: "ゲーム").click

      expect(page).to have_text("ゲーム")
      expect(find("[data-testid='tag-input']").value).to eq("")
    end

    it "1文字では候補が表示されない" do
      fill_in "tag-input", with: "ゲ"

      expect(page).not_to have_css("[data-testid='autocomplete-item']")
    end
  end

  describe "フォーム送信" do
    it "カードのタグが保存される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      expect(page).to have_content("ゲーム")
      expect(current_profile.reload.hobbies.pluck(:name)).to include("ゲーム")
    end
  end

  describe "Turbo再表示時のカード復元" do
    it "バリデーションエラー後もカードが復元される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      # hidden fieldを11個分のタグ（上限超過）に書き換えてバリデーションエラーを発生させる
      over_limit = ([ { name: "ゲーム", description: "" } ] + (1..10).map { |i| { name: "tag#{i}", description: "" } }).to_json
      page.execute_script("document.querySelector('[data-tag-autocomplete-target=\"hiddenField\"]').value = #{over_limit.to_json}")
      click_button "更新する"

      # バリデーションエラー後はタブがリセットされるため、タグタブを再度クリックする
      click_on "タグ"
      expect(page).to have_css("[data-testid='description-toggle']")
      expect(page).to have_text("ゲーム")
    end
  end

  describe "タグ件数カウンター" do
    it "初期表示で 0 / 10件 が表示される" do
      expect(page).to have_css("[data-testid='tag-count']", text: "0 / 10件")
    end

    it "タグ追加時にカウンターが更新される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      expect(page).to have_css("[data-testid='tag-count']", text: "1 / 10件")
    end

    it "タグ削除時にカウンターが更新される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      find("button[aria-label='ゲームを削除']", visible: :all).click

      expect(page).to have_css("[data-testid='tag-count']", text: "0 / 10件")
    end
  end
end
