require "rails_helper"

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /admin" do
    context "admin ユーザーの場合" do
      it "200 を返す" do
        admin_user = create(:user, :admin)
        sign_in admin_user

        get admin_root_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "非 admin ユーザーの場合" do
      it "root_path にリダイレクトされる" do
        user = create(:user)
        sign_in user

        get admin_root_path

        expect(response).to redirect_to(root_path)
      end

      it "「権限がありません」の alert が設定される" do
        user = create(:user)
        sign_in user

        get admin_root_path

        expect(flash[:alert]).to eq "権限がありません"
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        get admin_root_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
