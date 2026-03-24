require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /terms" do
    before { get terms_path }

    it "正常に表示される" do
      expect(response).to have_http_status(:ok)
    end

    it "利用規約の見出しが表示される" do
      expect(response.body).to include("利用規約")
    end

    it "フッターが表示される" do
      expect(response.body).to include("プライバシーポリシー")
      expect(response.body).to include("お問い合わせ")
    end
  end

  describe "GET /privacy" do
    before { get privacy_path }

    it "正常に表示される" do
      expect(response).to have_http_status(:ok)
    end

    it "プライバシーポリシーの見出しが表示される" do
      expect(response.body).to include("プライバシーポリシー")
    end
  end
end
