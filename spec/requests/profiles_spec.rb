require "rails_helper"

RSpec.describe "Profiles", type: :request do
  describe "GET /profiles" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "profiles一覧でタグが表示される" do
      profile = create(:profile)
      rails = create(:hobby, name: "rails")
      create(:profile_hobby, profile:, hobby: rails)

      get profiles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("rails")
    end

    it "一覧で趣味が0件の場合、未登録が表示される" do
      create(:profile)

      get profiles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("未登録")
    end
  end
end
