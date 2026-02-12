require 'rails_helper'

RSpec.describe "MyProfiles", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /my_profile/edit" do
    it "未作成なら、newへリダイレクトしalertが出る" do
      get edit_my_profile_path

      expect(response).to redirect_to(new_my_profile_path)
      follow_redirect!

      expect(response.body).to include("プロフィールを作成してください")
    end
  end

  describe "GET /my_profile/new" do
    it "作成済みなら一覧へリダイレクトしnoticeが出る" do
      create(:profile, user:)

      get new_my_profile_path

      expect(response).to redirect_to(profiles_path)
      follow_redirect!

      expect(response.body).to include("プロフィールは作成済みです")
    end
  end
end
