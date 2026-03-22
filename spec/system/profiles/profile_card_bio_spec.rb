require "rails_helper"

RSpec.describe "プロフィールカードのbio表示", type: :system, js: true do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  context "bioが入力されている場合" do
    it "カードにbioが表示される" do
      create(:profile, bio: "テスト自己紹介です")
      visit profiles_path

      expect(page).to have_text("テスト自己紹介です")
    end
  end

  context "bioが未入力の場合" do
    it "「未入力」と表示される" do
      create(:profile, bio: nil)
      visit profiles_path

      expect(page).to have_text("説明文は未入力です")
    end
  end
end
