require "rails_helper"

RSpec.describe "管理：親タグ一覧 ページネーション", type: :system do
  # セットアップ：chatタイプの親タグ11件（1ページ10件なので2ページ目が必要）
  let(:admin_user) { create(:user, :admin) }

  before do
    create_list(:parent_tag, 11, room_type: "chat")
    login_as(admin_user, scope: :user)
    visit admin_parent_tags_path
  end

  # アサーション：chatセクションに10件表示される
  it "chatセクションに10件の親タグ行が表示される" do
    within("section[data-room-type='chat']") do
      expect(page).to have_css("tbody tr", count: 10)
    end
  end

  # アサーション：chatセクションに「次へ」リンクが表示される
  it "chatセクションに次ページリンクが表示される" do
    within("section[data-room-type='chat']") do
      expect(page).to have_link("次へ ›")
    end
  end

  # アサーション：chatセクション2ページ目に1件表示される
  it "chatセクションの2ページ目に残りの1件が表示される" do
    within("section[data-room-type='chat']") do
      click_link "次へ ›"
    end
    within("section[data-room-type='chat']") do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end
end
