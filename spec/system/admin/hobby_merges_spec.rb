require "rails_helper"

RSpec.describe "Admin 趣味タグ統合", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:programming_parent_tag) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study) }
  let!(:game_parent_tag) { create(:parent_tag, name: "ゲーム", slug: "game", room_type: :game) }
  let!(:source_hobby) { create(:hobby, name: "Apex") }
  let!(:target_hobby) { create(:hobby, name: "React") }
  let!(:unclassified_hobby) { create(:hobby, name: "未分類タグ") }

  before do
    create(:hobby_parent_tag, hobby: source_hobby, parent_tag: game_parent_tag)
    create(:hobby_parent_tag, hobby: target_hobby, parent_tag: programming_parent_tag)
    login_as(admin_user, scope: :user)
  end

  describe "フォーム表示" do
    before { visit new_admin_hobby_merge_path }

    it "ページタイトルが表示される" do
      expect(page).to have_content "趣味タグ統合"
    end

    it "統合元セレクトが親タグごとと未分類に分かれている" do
      aggregate_failures do
        expect(page).to have_css("select#source_hobby_id optgroup[label='ゲーム'] option", text: "Apex")
        expect(page).to have_css("select#source_hobby_id optgroup[label='プログラミング'] option", text: "React")
        expect(page).to have_css("select#source_hobby_id optgroup[label='未分類'] option", text: "未分類タグ")
      end
    end

    it "統合先セレクトも同じセクション構成で表示される" do
      aggregate_failures do
        expect(page).to have_css("select#target_hobby_id optgroup[label='ゲーム'] option", text: "Apex")
        expect(page).to have_css("select#target_hobby_id optgroup[label='プログラミング'] option", text: "React")
        expect(page).to have_css("select#target_hobby_id optgroup[label='未分類'] option", text: "未分類タグ")
      end
    end
  end

  describe "統合実行", js: true do
    before { visit new_admin_hobby_merge_path }

    it "異なるタグを選択して統合するとflashが表示される" do
      select "Apex", from: "source_hobby_id"
      select "React", from: "target_hobby_id"

      accept_confirm { click_button "統合する" }

      expect(page).to have_content "「Apex」を「React」に統合しました"
    end

    it "統合後に統合元タグがフォームから消える" do
      select "Apex", from: "source_hobby_id"
      select "React", from: "target_hobby_id"

      accept_confirm { click_button "統合する" }

      expect(page).to have_no_css("select#source_hobby_id option", text: "Apex")
    end

    it "同じタグを選択するとエラーが表示される" do
      select "Apex", from: "source_hobby_id"
      select "Apex", from: "target_hobby_id"

      accept_confirm { click_button "統合する" }

      expect(page).to have_content "統合元と統合先が同じです"
    end
  end

  describe "アクセス制御" do
    it "一般ユーザーは root にリダイレクトされる" do
      login_as(create(:user), scope: :user)

      visit new_admin_hobby_merge_path

      expect(page).to have_current_path root_path
    end
  end
end
