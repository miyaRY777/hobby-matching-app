require "rails_helper"

RSpec.describe "公開部屋一覧ページネーション", type: :system do
  # セットアップ：11件の公開部屋（1ページ10件なので2ページ目が必要）
  let(:current_user) { create(:user) }

  before do
    room_owner_profile = create(:profile)
    create_list(:room, 11, issuer_profile: room_owner_profile, locked: false).each do |room|
      create(:share_link, room: room)
    end
    login_as(current_user, scope: :user)
    visit rooms_path
  end

  # アサーション：1ページ目は10件表示される
  it "1ページ目に10件の部屋行が表示される" do
    expect(page).to have_css("tbody tr", count: 10)
  end

  # アサーション：「次へ」リンクが表示される
  it "次ページへのリンクが表示される" do
    expect(page).to have_link("次へ ›")
  end

  # アサーション：2ページ目に1件表示される
  it "2ページ目に残りの1件が表示される" do
    click_link "次へ ›"
    expect(page).to have_css("tbody tr", count: 1)
  end
end
