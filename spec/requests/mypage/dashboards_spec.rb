require "rails_helper"

# /mypage へのアクセス条件とレスポンスの結果を確認すること
RSpec.describe "Mypage::Dashboards", type: :request do
  describe "GET /mypage" do
    context "ログインしている場合" do
      it "ダッシュボードが表示される" do
        user = create(:user)
        sign_in user

        get mypage_root_path

        expect(response).to have_http_status(:ok)
      end

      it "ニックネームが表示される" do
        user = create(:user, nickname: "たろう")
        sign_in user

        get mypage_root_path

        expect(response.body).to include("たろう")
      end

      it "趣味プロフィール編集へのリンクが表示される" do
        user = create(:user)
        create(:profile, user: user)
        sign_in user

        get mypage_root_path

        expect(response.body).to include(edit_my_profile_path)
      end

      it "部屋管理ページへのリンクと部屋数が表示される" do
        user = create(:user)
        profile = create(:profile, user: user)
        create(:room, issuer_profile: profile)
        create(:room, issuer_profile: profile)
        sign_in user

        get mypage_root_path

        expect(response.body).to include(mypage_rooms_path)
        expect(response.body).to include("2")
      end

      it "設定ページへのリンクが表示される" do
        user = create(:user)
        sign_in user

        get mypage_root_path

        expect(response.body).to include(mypage_settings_path)
      end

      it "ヘッダーにマイページリンクが表示される" do
        user = create(:user)
        sign_in user

        get mypage_root_path

        expect(response.body).to include("href=\"#{mypage_root_path}\"")
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        get mypage_root_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /mypage/dashboard" do
    context "ログインしている場合" do
      it "ニックネームを更新できる" do
        user = create(:user, nickname: "旧ニックネーム")
        sign_in user

        patch mypage_dashboard_path, params: { user: { nickname: "新ニックネーム" } }

        expect(user.reload.nickname).to eq("新ニックネーム")
      end

      it "空のニックネームでは更新できない" do
        user = create(:user, nickname: "旧ニックネーム")
        sign_in user

        patch mypage_dashboard_path, params: { user: { nickname: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.nickname).to eq("旧ニックネーム")
      end

      it "21文字以上のニックネームでは更新できない" do
        user = create(:user, nickname: "旧ニックネーム")
        sign_in user

        patch mypage_dashboard_path, params: { user: { nickname: "あ" * 21 } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.nickname).to eq("旧ニックネーム")
      end

      it "有効な画像をアップロードできる" do
        user = create(:user)
        sign_in user

        avatar = fixture_file_upload(
          Rails.root.join("spec/fixtures/files/valid_avatar.jpg"),
          "image/jpeg"
        )
        patch mypage_dashboard_path, params: { user: { avatar: avatar } }

        expect(response).to redirect_to(mypage_root_path)
        expect(user.reload.avatar).to be_attached
      end

      it "不正な形式のファイルはバリデーションエラーになる" do
        user = create(:user)
        sign_in user

        avatar = fixture_file_upload(
          Rails.root.join("spec/fixtures/files/invalid_avatar.bmp"),
          "image/bmp"
        )
        patch mypage_dashboard_path, params: { user: { avatar: avatar } }

        expect(response).to redirect_to(mypage_root_path)
        follow_redirect!
        expect(response.body).to include("ファイルタイプは許可されていません")
      end
    end
  end
end
