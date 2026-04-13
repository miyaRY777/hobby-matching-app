require "rails_helper"

RSpec.describe "Admin 未分類タグ管理", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:uncategorized_parent_tag) do
    ParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) { |pt| pt.name = "未分類" }
  end
  let!(:programming_parent_tag) do
    ParentTag.find_or_create_by!(slug: "programming", room_type: :study) do |pt|
      pt.name = "プログラミング"
      pt.position = 1
    end
  end

  before { login_as(admin_user, scope: :user) }

  describe "一覧表示" do
    let!(:unclassified_hobby) { create(:hobby, name: "rails", parent_tag: uncategorized_parent_tag) }
    let!(:classified_hobby)   { create(:hobby, name: "Ruby", parent_tag: programming_parent_tag) }

    before { visit admin_unclassified_hobbies_path }

    it "未分類タグが表示される" do
      expect(page).to have_content "rails"
    end

    it "分類済みタグは表示されない" do
      # 名前列にのみ絞って確認（mergeドロップダウンは全タグを含む）
      expect(page).not_to have_css("td[data-col='name']", text: "Ruby")
    end

    it "タグ名・使用回数・ユーザー数の列ヘッダーが表示される" do
      expect(page).to have_content "タグ名"
      expect(page).to have_content "使用回数"
      expect(page).to have_content "ユーザー数"
    end
  end

  describe "使用回数・ユーザー数の集計" do
    let!(:target_hobby) { create(:hobby, name: "python", parent_tag: uncategorized_parent_tag) }
    let!(:first_profile)  { create(:profile) }
    let!(:second_profile) { create(:profile) }

    before do
      # 2ユーザーがpythonタグを使用している
      create(:profile_hobby, profile: first_profile,  hobby: target_hobby)
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
    let!(:rails_hobby)  { create(:hobby, name: "rails",  parent_tag: uncategorized_parent_tag) }
    let!(:python_hobby) { create(:hobby, name: "python", parent_tag: uncategorized_parent_tag) }

    before { visit admin_unclassified_hobbies_path }

    it "検索ワードに一致するタグだけが表示される" do
      # rails で検索
      fill_in "q", with: "rails"
      click_button "検索"
      # 名前列にのみ絞って確認（mergeドロップダウンは全タグを含む）
      expect(page).to     have_css("td[data-col='name']", text: "rails")
      expect(page).not_to have_css("td[data-col='name']", text: "python")
    end
  end

  describe "分類" do
    let!(:unclassified_rails) { create(:hobby, name: "rails", parent_tag: uncategorized_parent_tag) }

    before { visit admin_unclassified_hobbies_path }

    it "親タグを選択して保存するとフラッシュが表示される" do
      # parent_tag_id selectで親タグを選択して分類ボタンを押す
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      expect(page).to have_content "分類しました"
    end

    it "分類後にparent_tag_idが更新される" do
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      expect(unclassified_rails.reload.parent_tag_id).to eq programming_parent_tag.id
    end

    it "分類後に一覧から消える" do
      select "プログラミング", from: "parent_tag_id"
      click_button "分類"
      expect(page).not_to have_css("td[data-col='name']", text: "rails")
    end
  end

  describe "統合" do
    let!(:source_rails_hobby)  { create(:hobby, name: "rails",  parent_tag: uncategorized_parent_tag) }
    let!(:target_Rails_hobby)  { create(:hobby, name: "Rails") }
    let!(:source_hobby_owner_profile) { create(:profile) }

    before do
      # sourceタグを持つプロフィールを作成
      create(:profile_hobby, profile: source_hobby_owner_profile, hobby: source_rails_hobby)
      visit admin_unclassified_hobbies_path
    end

    it "統合するとフラッシュが表示される" do
      within "[data-hobby-id='#{source_rails_hobby.id}']" do
        select "Rails", from: "target_hobby_id"
        click_button "統合"
      end
      expect(page).to have_content "統合しました"
    end

    it "統合後にprofile_hobbiesがtargetに付け替えられる" do
      within "[data-hobby-id='#{source_rails_hobby.id}']" do
        select "Rails", from: "target_hobby_id"
        click_button "統合"
      end
      expect(ProfileHobby.where(hobby_id: target_Rails_hobby.id, profile_id: source_hobby_owner_profile.id)).to exist
    end

    it "統合後にsource hobbyが削除される" do
      within "[data-hobby-id='#{source_rails_hobby.id}']" do
        select "Rails", from: "target_hobby_id"
        click_button "統合"
      end
      expect(Hobby.find_by(id: source_rails_hobby.id)).to be_nil
    end
  end

  describe "アクセス制御" do
    let!(:normal_user) { create(:user) }

    it "一般ユーザーはrootにリダイレクトされる" do
      # 一般ユーザーでログイン
      login_as(normal_user, scope: :user)
      visit admin_unclassified_hobbies_path
      expect(page).to have_current_path root_path
    end
  end
end
