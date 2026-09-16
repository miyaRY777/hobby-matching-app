require "rails_helper"

RSpec.describe "パスワードリセット画面", type: :system do
  describe "パスワードリセット申請画面" do
    before { visit new_user_password_path }

    it "「ログインに戻る」リンクが表示される" do
      expect(page).to have_link("ログインに戻る", href: new_user_session_path)
    end

    it "OAuthボタンが表示されない" do
      expect(page).not_to have_button("Google")
      expect(page).not_to have_button("Discord")
    end

    it "フォーム内に「ユーザー登録」リンクが表示されない" do
      within("div[style*='max-width: 28rem']") do
        expect(page).not_to have_link("ユーザー登録")
      end
    end

    it "カードがログイン画面と同じ位置指定である" do
      # 親レイアウトの中央寄せを、カード側でも上書きしない
      expect(page).to have_css("div[style*='max-width: 28rem'][style*='align-self: center']")
    end
  end

  describe "パスワード変更画面" do
    before do
      user = create(:user)
      token = user.send_reset_password_instructions
      visit edit_user_password_path(reset_password_token: token)
    end

    it "OAuthボタンが表示されない" do
      expect(page).not_to have_button("Google")
      expect(page).not_to have_button("Discord")
    end

    it "フォーム内に「ログイン」リンクが表示されない" do
      within("div[style*='max-width: 28rem']") do
        expect(page).not_to have_link("ログイン")
      end
    end

    it "カードがログイン画面と同じ位置指定である" do
      # 親レイアウトの中央寄せを、カード側でも上書きしない
      expect(page).to have_css("div[style*='max-width: 28rem'][style*='align-self: center']")
    end
  end
end
