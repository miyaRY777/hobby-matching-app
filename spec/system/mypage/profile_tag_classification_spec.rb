require "rails_helper"

RSpec.describe "タグ作成時の親タグ選択", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:fps) { create(:parent_tag, name: "FPS", slug: "fps", room_type: :game, position: 0) }

  before do
    login_as(current_user, scope: :user)
    visit edit_mypage_profile_path
    click_on "趣味"
  end

  describe "新規タグの即カード" do
    it "候補にないタグでは追加行だけが出て、分類フォームは出ない" do
      fill_in "tag-input", with: "新作ゲームタグ"

      expect(page).to have_css("[data-testid='new-tag-add-row']", text: "新作ゲームタグ")
      expect(page).to have_no_button("わからない")
      expect(page).to have_no_button("追加する")
      expect(page).to have_no_css("[data-testid='new-tag-parent-select']")
    end

    it "追加行をクリックすると未分類のカードがすぐ出る" do
      add_new_hobby_tag("新作ゲームタグ")

      expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
      expect(page).to have_css("[data-testid='tag-child-chip']", text: "新作ゲームタグ")
    end

    it "未分類のまま保存すると HobbyParentTag は付かない" do
      add_new_hobby_tag("未分類タグ")
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))
      hobby = Hobby.find_by(normalized_name: "未分類タグ")
      expect(hobby.hobby_parent_tags).to be_empty
    end
  end

  describe "既存タグのバッジ表示" do
    let!(:rails_hobby) { create(:hobby, name: "Rails") }
    let!(:programming) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study, position: 0) }
    let!(:hobby_parent_tag) { create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming) }

    it "autocomplete の候補に親タグ名バッジが表示される" do
      fill_in "tag-input", with: "Rai"

      expect(page).to have_css("[data-testid='autocomplete-item']", text: "Rails")
      expect(page).to have_css("[data-testid='autocomplete-badge']", text: "プログラミング")
    end

    it "既存タグを選択するとカードに親タグ名バッジが表示される" do
      fill_in "tag-input", with: "Rai"
      find("[data-testid='autocomplete-item']", text: "Rails").click

      expect(page).to have_css("[data-testid='tag-parent-label']", text: "プログラミング")
      expect(page).to have_css("[data-testid='tag-child-chip']", text: "Rails")
    end
  end
end
