require "rails_helper"

RSpec.describe "公開部屋一覧", type: :system do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:owner_profile) { create(:profile) }
  let!(:issued_room) { create(:room, issuer_profile: current_profile, label: "自分の部屋", locked: false) }
  let!(:joined_room) { create(:room, issuer_profile: owner_profile, label: "参加済みの部屋", locked: false) }
  let!(:unjoined_room) { create(:room, issuer_profile: owner_profile, label: "未参加の部屋", locked: false) }
  let!(:locked_room) { create(:room, issuer_profile: owner_profile, label: "非公開の部屋", locked: true) }

  before do
    create(:room_membership, room: issued_room, profile: current_profile)
    create(:room_membership, room: joined_room, profile: current_profile)
    login_as(current_user, scope: :user)
  end

  it "公開部屋一覧が表示される" do
    # アクション: 公開部屋一覧ページを開く
    visit rooms_path

    # アサーション: 公開部屋のみ表示される
    expect(page).to have_text("自分の部屋")
    expect(page).to have_text("参加済みの部屋")
    expect(page).to have_text("未参加の部屋")
    expect(page).to have_no_text("非公開の部屋")
  end

  it "自分が作成した部屋に作成した部屋バッジが表示される" do
    # アクション: 公開部屋一覧ページを開く
    visit rooms_path

    # アサーション: 自分の部屋に作成した部屋バッジが表示される
    within find("[id='#{ActionView::RecordIdentifier.dom_id(issued_room)}']") do
      expect(page).to have_text("作成した部屋")
    end
  end

  it "参加済み部屋に参加済みバッジが表示される" do
    # アクション: 公開部屋一覧ページを開く
    visit rooms_path

    # アサーション: 参加済みの部屋に参加済みバッジが表示される
    within find("[id='#{ActionView::RecordIdentifier.dom_id(joined_room)}']") do
      expect(page).to have_text("参加済み")
    end
  end

  it "未参加部屋に参加するボタンが表示される" do
    # アクション: 公開部屋一覧ページを開く
    visit rooms_path

    # アサーション: 未参加の部屋に参加するボタンが表示される
    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      expect(page).to have_button("参加する")
    end
  end

  it "参加するボタンを押すと参加済みバッジに変わる" do
    # アクション: 公開部屋一覧で未参加の部屋に参加する
    visit rooms_path

    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      click_button "参加する"
    end

    # アサーション: 参加済み表示に変わり、参加情報も作成される
    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      expect(page).to have_text("参加済み")
      expect(page).to have_no_button("参加する")
    end
    expect(RoomMembership.exists?(room: unjoined_room, profile: current_profile)).to be true
  end
end
