require "rails_helper"

RSpec.describe "Profiles avatar display", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /profiles (一覧)" do
    context "アバター未設定のプロフィールがある場合" do
      it "デフォルトアイコンが表示される" do
        create(:profile)

        get profiles_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-testid="avatar"')
      end
    end
  end

  describe "GET /profiles/:id (詳細)" do
    context "アバター未設定のプロフィールの場合" do
      it "デフォルトアイコンが表示される" do
        profile = create(:profile)

        get profile_path(profile)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-testid="avatar"')
      end
    end
  end
end
