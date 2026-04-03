require 'rails_helper'

RSpec.describe "My::Profile", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /my/profile/edit" do
    it "未作成なら、newへリダイレクトしalertが出る" do
      get edit_my_profile_path

      expect(response).to redirect_to(new_my_profile_path)
      follow_redirect!

      expect(response.body).to include("プロフィールを作成してください")
    end
  end

  describe "PATCH /my/profile" do
    let!(:profile) { create(:profile, user:) }
    let!(:uncategorized) { ParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) { |pt| pt.name = "未分類"; pt.position = 0 } }

    it "11個のタグで更新するとバリデーションエラーになる" do
      hobbies_text = (1..11).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      patch my_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "10個以下のタグで更新すると成功する" do
      hobbies_text = (1..10).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      patch my_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to have_http_status(:found)
    end
  end

  describe "POST /my/profile" do
    it "11個のタグで作成するとバリデーションエラーになりタグデータが保持される" do
      hobbies_text = (1..11).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      post my_profile_path, params: { profile: { hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("タグ1")
    end
  end

  describe "GET /my/profile/new" do
    it "作成済みなら一覧へリダイレクトしnoticeが出る" do
      create(:profile, user:)

      get new_my_profile_path

      expect(response).to redirect_to(profiles_path)
      follow_redirect!

      expect(response.body).to include("プロフィールは作成済みです")
    end
  end
end
