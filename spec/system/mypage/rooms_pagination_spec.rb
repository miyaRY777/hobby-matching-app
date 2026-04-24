require "rails_helper"

RSpec.describe "マイページ部屋一覧ページネーション", type: :system do
  # セットアップ：管理中6件・参加中6件（合計12件、1ページ10件なので2ページ目が必要）
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # 管理中6件
    create_list(:room, 6, issuer_profile: current_profile).each do |room|
      create(:room_membership, room: room, profile: current_profile)
      create(:share_link, room: room)
    end
    # 参加中6件（別ユーザーが作成）
    other_profile = create(:profile)
    create_list(:room, 6, issuer_profile: other_profile).each do |room|
      create(:room_membership, room: room, profile: current_profile)
      create(:share_link, room: room)
    end

    login_as(current_user, scope: :user)
    visit mypage_rooms_path
  end

  # アサーション：1ページ目に10件表示される
  it "1ページ目に10件の部屋行が表示される" do
    expect(page).to have_css("tbody#rooms_tbody tr", count: 10)
  end

  # アサーション：「次へ」リンクが表示される
  it "次ページへのリンクが表示される" do
    expect(page).to have_link("次へ ›")
  end

  # アサーション：2ページ目に2件表示される
  it "2ページ目に残りの2件が表示される" do
    click_link "次へ ›"
    expect(page).to have_css("tbody#rooms_tbody tr", count: 2)
  end
end
