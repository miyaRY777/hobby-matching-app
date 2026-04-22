require "rails_helper"
require "nokogiri"

# /mypage へのアクセス条件とレスポンスの結果を確認すること
RSpec.describe "Mypage::Dashboards", type: :request do
  def dashboard_menu_links(response_body)
    document = Nokogiri::HTML.parse(response_body)
    document.css("div[style*='grid-template-columns'] > a")
  end

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

      it "プロフィール未作成ならプロフィール作成リンクが表示される" do
        user = create(:user)
        sign_in user

        get mypage_root_path

        menu_links = dashboard_menu_links(response.body)

        expect(menu_links.map(&:text).map(&:strip)).to include("プロフィールを作成する")
        expect(response.body).to include(new_my_profile_path)
        expect(response.body).not_to include("趣味プロフィール編集")
      end

      it "プロフィール未作成でも部屋管理と設定の導線は表示される" do
        user = create(:user)
        sign_in user

        get mypage_root_path

        menu_links = dashboard_menu_links(response.body)
        menu_texts = menu_links.map(&:text).map { |text| text.gsub(/\s+/, " ").strip }

        # 6ブロック（プロフィール作成・プロフィール一覧・使い方・部屋管理・公開部屋一覧・設定）が表示されている
        expect(menu_links.size).to eq(6)
        expect(menu_texts).to include("プロフィールを作成する")
        expect(menu_texts).to include("部屋管理 0 部屋")
        expect(menu_texts.any? { |t| t.include?("公開部屋一覧") }).to be true
        expect(menu_texts).to include("プロフィール一覧")
        expect(menu_texts).to include("設定")
        expect(menu_texts).to include("使い方")
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

      it "プロフィール一覧へのリンクが表示される" do
        current_user = create(:user)
        sign_in current_user

        # マイページにアクセス
        get mypage_root_path

        # メニューグリッド内のリンク一覧を取得
        menu_links = dashboard_menu_links(response.body)

        # プロフィール一覧パスへのリンクがメニュー内に含まれている
        expect(menu_links.map { |a| a["href"] }).to include(profiles_path)
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
