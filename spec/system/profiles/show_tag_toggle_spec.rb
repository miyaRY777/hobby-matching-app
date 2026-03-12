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

  it "ページを開くと最初のタグの説明文が自動表示される" do
    expect(page).to have_text("毎日やってます")
  end

  it "アクティブなタグを再クリックしても説明文が表示されたままになる" do
    expect(page).to have_text("毎日やってます")
    find("[data-testid='toggle-tag']", text: "ゲーム").click
    expect(page).to have_text("毎日やってます")
  end

  it "別のタグをクリックすると説明文が切り替わる" do
    hobby2 = create(:hobby, name: "釣り")
    create(:profile_hobby, profile: owner_profile, hobby: hobby2, description: "週末に行きます")
    visit profile_path(owner_profile)

    find("[data-testid='toggle-tag']", text: "釣り").click
    expect(page).to have_text("週末に行きます")
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
