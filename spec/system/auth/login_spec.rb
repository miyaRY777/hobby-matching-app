require "rails_helper"

RSpec.describe "ログイン画面", type: :system do
  before { visit new_user_session_path }

  it "「パスワードをお忘れですか？」リンクが表示される" do
    expect(page).to have_link("パスワードをお忘れですか？", href: new_user_password_path)
  end

  it "「ユーザー登録はこちら」リンクが表示される" do
    expect(page).to have_link("ユーザー登録はこちら", href: new_user_registration_path)
  end

  it "「ログイン状態を保持する」チェックボックスが表示される" do
    expect(page).to have_field("ログイン状態を保持する", type: :checkbox)
  end

  describe "remember me" do
    # ビューのラベルにfor属性がないため、fill_in はフィールドIDで指定する
    let(:password) { "password123" }
    let(:login_user) { create(:user, password: password) }

    before do
      fill_in "user_email", with: login_user.email
      fill_in "user_password", with: password
    end

    it "チェックボックスをオンにしてログインすると remember_created_at が設定される" do
      check "ログイン状態を保持する"
      click_button "ログイン"

      # Devise がサーバー側で remember_created_at を更新することを確認
      expect(login_user.reload.remember_created_at).to be_present
    end

    it "チェックボックスをオフにしてログインすると remember_created_at が設定されない" do
      # チェックボックスはデフォルトでオフ（デフォルト動作の確認）
      click_button "ログイン"

      expect(login_user.reload.remember_created_at).to be_nil
    end
  end
end
