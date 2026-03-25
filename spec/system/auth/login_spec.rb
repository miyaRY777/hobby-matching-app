require "rails_helper"

RSpec.describe "ログイン画面", type: :system do
  before { visit new_user_session_path }

  it "「パスワードをお忘れですか？」リンクが表示される" do
    expect(page).to have_link("パスワードをお忘れですか？", href: new_user_password_path)
  end

  it "「ユーザー登録はこちら」リンクが表示される" do
    expect(page).to have_link("ユーザー登録はこちら", href: new_user_registration_path)
  end
end
