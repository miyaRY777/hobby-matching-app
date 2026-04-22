require "rails_helper"

RSpec.describe "公開部屋一覧", type: :system, js: true do
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:owner_profile) { create(:profile) }
  let!(:issued_room) { create(:room, issuer_profile: current_profile, label: "自分の部屋", locked: false) }
  let!(:joined_room) { create(:room, issuer_profile: owner_profile, label: "参加済みの部屋", locked: false) }
  let!(:unjoined_room) { create(:room, issuer_profile: owner_profile, label: "未参加の部屋", locked: false) }
  let!(:locked_room) { create(:room, issuer_profile: owner_profile, label: "非公開の部屋", locked: true) }
  let!(:unjoined_room_share_link) { create(:share_link, room: unjoined_room, token: "system-room-token", expires_at: 1.year.from_now) }

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

  it "自分がOwnerにOwnerバッジが表示される" do
    # アクション: 公開部屋一覧ページを開く
    visit rooms_path

    # アサーション: 自分の部屋にOwnerバッジが表示される
    within find("[id='#{ActionView::RecordIdentifier.dom_id(issued_room)}']") do
      expect(page).to have_text("Owner")
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

  it "モーダルの参加するボタンを押すと共有ページへ遷移する" do
    visit rooms_path

    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      click_button "参加する"
    end

    within("[data-testid='room-modal-#{unjoined_room.id}']") do
      click_button "参加する"
    end

    expect(page).to have_current_path(share_path(unjoined_room_share_link.token), ignore_query: true)
    expect(RoomMembership.exists?(room: unjoined_room, profile: current_profile)).to be true
  end

  it "参加するボタンをクリックするとモーダルが開く" do
    visit rooms_path

    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      click_button "参加する"
    end

    expect(page).to have_css("[data-testid='room-modal-#{unjoined_room.id}']", visible: true)
    expect(page).to have_text("未参加の部屋")
  end

  it "モーダルの一覧に戻るボタンを押すとモーダルが閉じる" do
    visit rooms_path

    within find("[id='#{ActionView::RecordIdentifier.dom_id(unjoined_room)}']") do
      click_button "参加する"
    end

    within("[data-testid='room-modal-#{unjoined_room.id}']") do
      click_button "一覧に戻る"
    end

    expect(page).to have_css("[data-testid='room-modal-#{unjoined_room.id}']", visible: false)
  end
end
