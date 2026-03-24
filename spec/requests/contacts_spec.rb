require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "GET /contacts/new" do
    before { get new_contact_path }

    it "正常に表示される" do
      expect(response).to have_http_status(:ok)
    end

    it "フォームが表示される" do
      expect(response.body).to include("お問い合わせ")
    end
  end

  describe "POST /contacts" do
    let(:valid_params) do
      { contact_form: { name: "テスト太郎", email: "test@example.com", subject: "テスト件名", body: "お問い合わせ内容です。" } }
    end
    let(:invalid_params) do
      { contact_form: { name: "", email: "", subject: "", body: "" } }
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CONTACT_EMAIL", anything).and_return("admin@example.com")
    end

    context "正常な入力の場合" do
      it "トップページにリダイレクトされる" do
        post contacts_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "フラッシュメッセージが表示される" do
        post contacts_path, params: valid_params
        expect(flash[:notice]).to be_present
      end

      it "メールが送信される" do
        expect {
          post contacts_path, params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "入力が不正な場合" do
      it "422が返る" do
        post contacts_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "フォームが再表示される" do
        post contacts_path, params: invalid_params
        expect(response.body).to include("お問い合わせ")
      end
    end
  end
end
