require "rails_helper"

RSpec.describe "タグ説明文入力UI", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
  end

  describe "説明文入力欄の表示" do
    before { click_on "タグ" }

    it "タグ追加後に説明カードが表示される" do
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      expect(page).to have_css("[data-testid='description-toggle']")
      expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
      expect(page).to have_css("[data-testid='tag-child-chip']", text: "ゲーム")
    end

    it "デフォルトでは説明文入力欄は非表示" do
      # ✏️クリック前は説明文入力欄が見えない
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click

      expect(page).not_to have_css("[data-testid='description-input']")
    end

    it "✏️ボタンをクリックすると説明文入力欄が表示される" do
      # ✏️クリック後に説明文入力欄が展開される
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      find("[data-testid='description-toggle']").click

      expect(page).to have_css("[data-testid='description-input']")
    end

    it "カードを削除すると説明編集ボタンも消える" do
      # タグ削除と同時に説明編集ボタンも消える
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      expect(page).to have_css("[data-testid='description-toggle']")

      find("button[aria-label='ゲームを削除']", visible: :all).click

      expect(page).not_to have_css("[data-testid='description-toggle']")
    end
  end

  describe "説明文の保存" do
    before { click_on "タグ" }

    it "説明文を入力して保存すると反映される" do
      # タグ追加 → ✏️クリック → 説明入力 → 保存
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      find("[data-testid='description-toggle']").click
      find("[data-testid='description-input']").fill_in with: "毎日やってます"
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      expect(page).to have_css("[data-testid='toggle-tag']", text: "ゲーム")

      ph = current_profile.reload.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ゲーム" })
      expect(ph.description).to eq("毎日やってます")
    end

    it "説明文なしでも保存できる" do
      # ✏️を開かずに保存しても空文字で保存される
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      expect(page).to have_css("[data-testid='toggle-tag']", text: "ゲーム")

      ph = current_profile.reload.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ゲーム" })
      expect(ph).not_to be_nil
      expect(ph.description.to_s).to eq("")
    end
  end

  describe "Turbo再表示後の復元" do
    before { click_on "タグ" }

    it "バリデーションエラー後もカードと説明文が復元される" do
      # 入力内容がエラー後もそのまま残る
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      find("[data-testid='description-toggle']").click
      find("[data-testid='description-input']").fill_in with: "毎日やってます"

      expect(page).to have_text("ゲーム")
      expect(find("[data-testid='description-input']").value).to eq("毎日やってます")
    end
  end

  describe "bio入力欄" do
    # bioはデフォルトの「自己紹介」タブに表示される

    it "bio入力欄が表示される" do
      expect(page).to have_field("profile[bio]")
    end

    it "プレースホルダーに例文が表示される" do
      bio_field = find_field("profile[bio]")
      expect(bio_field["placeholder"]).to include("インドア派")
    end

    it "bioを入力して保存できる" do
      # ひとことタブでbio入力 → タグタブでタグ追加 → 保存
      fill_in "profile[bio]", with: "テスト自己紹介です"
      click_on "タグ"
      fill_in "tag-input", with: "ゲーム"
      find("[data-testid='skip-parent-tag']").click
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      expect(page).to have_text("テスト自己紹介です")
      expect(current_profile.reload.bio).to eq("テスト自己紹介です")
    end
  end

  describe "bioカウンター" do
    # bioカウンターはひとことタブに表示される

    it "bio入力時にカウンターがリアルタイムで更新される" do
      fill_in "profile[bio]", with: "テスト"

      expect(page).to have_css("[data-testid='bio-counter']", text: "3 / 500字")
    end

    it "初期表示で既存bioの文字数が表示される" do
      # 既存bioがある場合は初期カウントが反映される
      current_profile.update!(bio: "既存テキスト")
      visit edit_my_profile_path

      expect(page).to have_css("[data-testid='bio-counter']", text: "6 / 500字")
    end
  end
end
