require "rails_helper"

RSpec.describe "プロフィール詳細タグ切り替え", type: :system, js: true do
  let(:owner) { create(:user) }
  let(:viewer) { create(:user) }
  let!(:owner_profile) { create(:profile, user: owner) }
  let!(:hobby) { create(:hobby, name: "ゲーム") }

  before do
    create(:profile_hobby, profile: owner_profile, hobby:, description: "毎日やってます")
    login_as(viewer, scope: :user)
    visit profile_path(owner_profile)
  end

  it "タグをクリックすると説明文が表示される" do
    expect(page).not_to have_text("毎日やってます")
    find("[data-testid='toggle-tag']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
  end

  it "もう一度クリックすると説明文が非表示になる" do
    find("[data-testid='toggle-tag']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
    find("[data-testid='toggle-tag']", text: "ゲーム").click
    expect(page).not_to have_text("毎日やってます")
  end

  it "説明文が未入力の場合は「未入力」と表示される" do
    hobby2 = create(:hobby, name: "釣り")
    create(:profile_hobby, profile: owner_profile, hobby: hobby2, description: nil)
    visit profile_path(owner_profile)
    find("[data-testid='toggle-tag']", text: "釣り").click
    expect(page).to have_text("未入力")
  end
end
