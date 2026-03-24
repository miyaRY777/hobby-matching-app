require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "未ログイン時" do
      before { get root_path }

      it "LPが正常に表示される" do
        expect(response).to have_http_status(:ok)
      end

      it "ヒーローセクションのキャッチコピーが表示される" do
        expect(response.body).to include("一瞬で解決")
      end

      it "3つの特徴セクションが表示される" do
        expect(response.body).to include("Point 01")
        expect(response.body).to include("Point 02")
        expect(response.body).to include("Point 03")
      end

      it "使い方の流れセクションが表示される" do
        expect(response.body).to include("Step 01")
        expect(response.body).to include("Step 02")
        expect(response.body).to include("Step 03")
        expect(response.body).to include("Step 04")
      end

      it "ユーザー登録リンクが表示される" do
        expect(response.body).to include("無料で始める")
      end

      it "フッターが表示される" do
        expect(response.body).to include("利用規約")
        expect(response.body).to include("プライバシーポリシー")
        expect(response.body).to include("お問い合わせ")
      end
    end

    context "ログイン済み時" do
      let(:user) { create(:user) }

      before do
        sign_in user
        get root_path
      end

      it "プロフィール一覧へのリンクが表示される" do
        expect(response.body).to include("プロフィール一覧へ")
      end
    end
  end
end
