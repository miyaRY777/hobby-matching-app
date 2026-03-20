require "rails_helper"

RSpec.describe "Mypage::Settings", type: :request do
  describe "GET /mypage/settings" do
    context "ログインしている場合" do
      it "設定ページが表示される" do
        user = create(:user)
        sign_in user

        get mypage_settings_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        get mypage_settings_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /mypage/settings" do
    context "正しいパスワードで変更する場合" do
      it "パスワードが変更される" do
        user = create(:user, password: "password123")
        sign_in user

        patch mypage_settings_path, params: {
          user: {
            current_password: "password123",
            password: "newpassword456",
            password_confirmation: "newpassword456"
          }
        }

        expect(response).to redirect_to(mypage_settings_path)
        expect(user.reload.valid_password?("newpassword456")).to be true
      end
    end

    context "現在のパスワードが間違っている場合" do
      it "エラーが表示される" do
        user = create(:user, password: "password123")
        sign_in user

        patch mypage_settings_path, params: {
          user: {
            current_password: "wrongpassword",
            password: "newpassword456",
            password_confirmation: "newpassword456"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "新しいパスワードが短すぎる場合" do
      it "エラーが表示される" do
        user = create(:user, password: "password123")
        sign_in user

        patch mypage_settings_path, params: {
          user: {
            current_password: "password123",
            password: "short",
            password_confirmation: "short"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "確認用パスワードが一致しない場合" do
      it "エラーが表示される" do
        user = create(:user, password: "password123")
        sign_in user

        patch mypage_settings_path, params: {
          user: {
            current_password: "password123",
            password: "newpassword456",
            password_confirmation: "different789"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
