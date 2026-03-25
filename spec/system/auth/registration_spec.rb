require "rails_helper"

RSpec.describe "ユーザー登録画面", type: :system do
  before { visit new_user_registration_path }

  it "「ログインはこちら」リンクが表示される" do
    expect(page).to have_link("ログインはこちら", href: new_user_session_path)
  end
end
