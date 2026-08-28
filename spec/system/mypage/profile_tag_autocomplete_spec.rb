require "rails_helper"

RSpec.describe "タグ入力チップUI", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # タグ操作は趣味タブで行う
    login_as(current_user, scope: :user)
    visit edit_mypage_profile_path
    click_on "趣味"
  end

  describe "タグの追加" do
    it "候補がないタグは追加行クリックで即カードになる" do
      add_new_hobby_tag("ゲーム")

      expect(page).to have_css("[data-testid='tag-child-chip']", text: "ゲーム")
      expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
      expect(page).to have_no_button("わからない")
      expect(page).to have_no_button("追加する")
      expect(page).to have_no_css("[data-testid='new-tag-parent-select']")
    end

    it "候補を選んでいない状態で Enter すると即カードになる" do
      fill_in "tag-input", with: "ボードゲーム"
      find("[data-testid='tag-input']").send_keys(:enter)

      expect(page).to have_css("[data-testid='tag-child-chip']", text: "ボードゲーム")
      expect(find("[data-testid='tag-input']").value).to eq("")
    end

    it "2文字以上入力しただけではカードが増えない" do
      fill_in "tag-input", with: "ゲーム"

      expect(page).to have_css("[data-testid='new-tag-add-row']")
      expect(page).to have_no_css("[data-testid='tag-card']")
    end

    it "同一タグは重複追加できない" do
      add_new_hobby_tag("ゲーム")

      fill_in "tag-input", with: "ゲーム"
      expect(page).to have_text("ゲーム")
      expect(page).to have_css("[data-testid='description-toggle']", count: 1)
    end

    it "入力した表示名の大文字小文字を保ったままカードに追加できる" do
      add_new_hobby_tag("Ruby Rails")

      expect(page).to have_css("[data-testid='tag-child-chip']", text: "Ruby Rails")
    end

    it "10個追加するとinputが無効化される" do
      10.times do |i|
        add_new_hobby_tag("タグ#{i}")
      end

      expect(page).to have_css("[data-testid='description-toggle']", count: 10)
      expect(find("[data-testid='tag-input']")[:disabled]).to eq("true")
    end
  end

  describe "タグの削除" do
    it "カードの×ボタンでタグを削除できる" do
      # タグを追加してから削除する
      add_new_hobby_tag("ゲーム")
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
      add_new_hobby_tag("ゲーム")
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      expect(page).to have_content("ゲーム")
      expect(current_profile.reload.hobbies.pluck(:name)).to include("ゲーム")
    end
  end

  describe "Turbo再表示時のカード復元" do
    it "バリデーションエラー後もカードが復元される" do
      add_new_hobby_tag("ゲーム")

      # hidden fieldを11個分のタグ（上限超過）に書き換えてバリデーションエラーを発生させる
      over_limit = ([ { name: "ゲーム", description: "" } ] + (1..10).map { |i| { name: "tag#{i}", description: "" } }).to_json
      page.execute_script("document.querySelector('[data-tag-autocomplete-target=\"hiddenField\"]').value = #{over_limit.to_json}")
      click_button "更新する"

      # バリデーションエラー後はタブがリセットされるため、趣味タブを再度クリックする
      click_on "趣味"
      expect(page).to have_css("[data-testid='description-toggle']", visible: :all)
      expect(page).to have_css(
        "[data-testid='tag-card']",
        text: "ゲーム",
        visible: :all
      )
    end
  end

  describe "タグ件数カウンター" do
    it "初期表示で 0 / 10件 が表示される" do
      expect(page).to have_css("[data-testid='tag-count']", text: "0 / 10件")
    end

    it "タグ追加時にカウンターが更新される" do
      add_new_hobby_tag("ゲーム")

      expect(page).to have_css("[data-testid='tag-count']", text: "1 / 10件")
    end

    it "タグ削除時にカウンターが更新される" do
      add_new_hobby_tag("ゲーム")
      find("button[aria-label='ゲームを削除']", visible: :all).click

      expect(page).to have_css("[data-testid='tag-count']", text: "0 / 10件")
    end
  end
end
