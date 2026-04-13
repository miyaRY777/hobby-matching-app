require "rails_helper"

RSpec.describe "Admin 親タグ管理", type: :system do
  let!(:admin_user) { create(:user, :admin) }
  let!(:chat_parent_tag) { create(:parent_tag, name: "アニメ", room_type: :chat, position: 1) }
  let!(:study_parent_tag) { create(:parent_tag, name: "資格", room_type: :study, position: 2) }
  let!(:game_parent_tag) { create(:parent_tag, name: "FPS", room_type: :game, position: 3) }
  let!(:uncategorized_parent_tag) do
    ParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) { |pt| pt.name = "未分類" }
  end
  let!(:chat_hobby) do
    hobby = create(:hobby, name: "進撃の巨人")
    create(:hobby_parent_tag, hobby:, parent_tag: chat_parent_tag)
    hobby
  end
  let!(:used_hobby) do
    hobby = create(:hobby, name: "簿記")
    create(:hobby_parent_tag, hobby:, parent_tag: study_parent_tag)
    hobby
  end

  before do
    create(:profile_hobby, hobby: used_hobby)
    login_as(admin_user, scope: :user)
  end

  it "一覧で room_type ごとのセクション、フィルター、CRUD 導線、ナビリンクを表示できる" do
    visit admin_parent_tags_path

    expect(page).to have_link("親タグ管理", href: admin_parent_tags_path)
    expect(page).to have_select("room_type")
    expect(page).to have_select("parent_tag_id")

    expect(page).to have_content("chat")
    expect(page).to have_content("study")
    expect(page).to have_content("game")
    expect(page).to have_content("アニメ")
    expect(page).to have_content("進撃の巨人")
    expect(page).to have_content("簿記")
    expect(page).not_to have_css("td[data-col='parent-tag']", text: "未分類")

    expect(page).to have_link("＋親タグ作成", href: new_admin_parent_tag_path(room_type: "chat"))
    expect(page).to have_link("＋子タグ作成", href: new_admin_hobby_path(parent_tag_id: chat_parent_tag.id))
  end

  it "フィルターで親タグを絞り込める" do
    visit admin_parent_tags_path

    select "study", from: "room_type"
    click_button "検索"

    expect(page).to have_css("td[data-col='parent-tag']", text: "資格")
    expect(page).to have_css("td[data-col='hobby-name']", text: "簿記")
    expect(page).not_to have_css("td[data-col='parent-tag']", text: "アニメ")
  end

  it "使用中の子タグを削除しようとするとエラーが表示される" do
    visit admin_parent_tags_path

    within "[data-hobby-id='#{used_hobby.id}']" do
      click_button "削除"
    end

    expect(page).to have_content("使用中のため削除できません（1件が使用中）")
  end
end
