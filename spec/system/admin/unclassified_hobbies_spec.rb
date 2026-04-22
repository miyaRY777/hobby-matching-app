require "rails_helper"

RSpec.describe "Admin 未分類タグ管理", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:programming_parent_tag) do
    create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study, position: 1)
  end

  before { login_as(admin_user, scope: :user) }

  describe "一覧表示" do
    let!(:unclassified_hobby) { create(:hobby, name: "rails") }
    let!(:classified_hobby) do
      hobby = create(:hobby, name: "Ruby")
      create(:hobby_parent_tag, hobby:, parent_tag: programming_parent_tag)
      hobby
    end

    before { visit admin_unclassified_hobbies_path }

    it "未分類タグが表示される" do
      expect(page).to have_content "rails"
    end

    it "分類済みタグは表示されない" do
      expect(page).not_to have_css("td[data-col='name']", text: "Ruby")
    end

    it "タグ名・使用回数・ユーザー数の列ヘッダーが表示される" do
      expect(page).to have_content "タグ名"
      expect(page).to have_content "使用回数"
      expect(page).to have_content "ユーザー数"
    end
  end

  describe "使用回数・ユーザー数の集計" do
    let!(:target_hobby) { create(:hobby, name: "python") }
    let!(:first_profile) { create(:profile) }
    let!(:second_profile) { create(:profile) }

    before do
      create(:profile_hobby, profile: first_profile, hobby: target_hobby)
      create(:profile_hobby, profile: second_profile, hobby: target_hobby)
      visit admin_unclassified_hobbies_path
    end

    it "使用回数が2と表示される" do
      within "[data-hobby-id='#{target_hobby.id}']" do
        expect(page).to have_content "2"
      end
    end
  end

  describe "検索" do
    let!(:rails_hobby) { create(:hobby, name: "rails") }
    let!(:python_hobby) { create(:hobby, name: "python") }

    before { visit admin_unclassified_hobbies_path }

    it "検索ワードに一致するタグだけが表示される" do
      fill_in "q", with: "rails"
      click_button "検索"
      expect(page).to have_css("td[data-col='name']", text: "rails")
      expect(page).not_to have_css("td[data-col='name']", text: "python")
    end
  end

  describe "分類" do
    let!(:unclassified_rails) { create(:hobby, name: "rails") }

    before { visit admin_unclassified_hobbies_path }

    it "親タグを選択して保存するとフラッシュが表示される" do
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      expect(page).to have_content "分類しました"
    end

    it "分類後に hobby_parent_tag が作成される" do
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      hobby_parent_tag = unclassified_rails.hobby_parent_tags.reload.find_by(room_type: programming_parent_tag.room_type)
      expect(hobby_parent_tag&.parent_tag).to eq(programming_parent_tag)
    end

    it "分類後に一覧から消える" do
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      expect(page).not_to have_css("td[data-col='name']", text: "rails")
    end
  end

  describe "削除", js: true do
    let!(:unused_hobby) { create(:hobby, name: "unused-tag") }
    let!(:used_hobby) { create(:hobby, name: "used-tag") }
    let!(:owner_profile) { create(:profile) }

    before do
      create(:profile_hobby, profile: owner_profile, hobby: used_hobby)
      visit admin_unclassified_hobbies_path
    end

    it "usage_count が 0 のタグに削除ボタンが表示される" do
      within "[data-hobby-id='#{unused_hobby.id}']" do
        expect(page).to have_button "削除"
      end
    end

    it "usage_count が 1 以上のタグに削除ボタンが表示されず「使用中」と表示される" do
      within "[data-hobby-id='#{used_hobby.id}']" do
        expect(page).not_to have_button "削除"
        expect(page).to have_content "使用中"
      end
    end

    it "削除後にタグが一覧から消えてフラッシュが表示される" do
      within "[data-hobby-id='#{unused_hobby.id}']" do
        accept_confirm { click_button "削除" }
      end
      expect(page).not_to have_css("[data-hobby-id='#{unused_hobby.id}']")
      expect(page).to have_content "削除しました"
    end
  end

  describe "アクセス制御" do
    let!(:normal_user) { create(:user) }

    it "一般ユーザーはrootにリダイレクトされる" do
      login_as(normal_user, scope: :user)
      visit admin_unclassified_hobbies_path
      expect(page).to have_current_path root_path
    end
  end
end
