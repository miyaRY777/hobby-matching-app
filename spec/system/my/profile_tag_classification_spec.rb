require "rails_helper"

RSpec.describe "タグ作成時の親タグ選択", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:fps) { create(:parent_tag, name: "FPS", slug: "fps", room_type: :game, position: 0) }

  before do
    login_as(current_user, scope: :user)
    visit edit_my_profile_path
    click_on "タグ"
  end

  describe "新規タグの親タグ選択" do
    it "候補にないタグを追加すると新規追加セクションが表示される" do
      fill_in "tag-input", with: "新作ゲームタグ"

      expect(page).to have_button("わからない")
      expect(page).to have_button("追加する")
    end

    it "親タグを選んで追加するとカードにバッジが表示される" do
      fill_in "tag-input", with: "新作ゲームタグ"
      expect(page).to have_button("わからない")
      find("select").find("option", text: "FPS").select_option
      click_button "追加する"

      expect(page).to have_css("[data-testid='tag-parent-label']", text: "FPS")
      expect(page).to have_css("[data-testid='tag-child-chip']", text: "新作ゲームタグ")
    end

    it "わからないを選んで追加するとバッジなしのカードが表示される" do
      fill_in "tag-input", with: "未分類タグ"
      expect(page).to have_button("わからない")
      click_button "わからない"

      expect(page).to have_css("[data-testid='tag-parent-label']", text: "未分類")
      expect(page).to have_css("[data-testid='tag-child-chip']", text: "未分類タグ")
    end

    it "保存すると親タグ選択が DB に反映される" do
      fill_in "tag-input", with: "新規タグ123"
      expect(page).to have_button("わからない")
      find("select").find("option", text: "FPS").select_option
      click_button "追加する"
      click_button "更新する"

      expect(page).to have_current_path(profile_path(current_profile))

      hobby = Hobby.find_by(normalized_name: "新規タグ123")
      expect(hobby.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(fps)
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
