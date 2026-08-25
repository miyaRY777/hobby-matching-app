require 'rails_helper'

RSpec.describe "Mypage::Profile", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /mypage/profile/edit" do
    it "未作成なら、newへリダイレクトしalertが出る" do
      get edit_mypage_profile_path

      expect(response).to redirect_to(new_mypage_profile_path)
      follow_redirect!

      expect(response.body).to include("プロフィールを作成してください")
    end

    context "プロフィール作成済み" do
      let!(:profile) { create(:profile, user:) }
      let(:programming) { create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study) }

      it "hobbies_text に parent_tag_name と room_type が含まれる" do
        rails_hobby = create(:hobby, name: "Rails")
        create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming)
        create(:profile_hobby, profile:, hobby: rails_hobby)

        get edit_mypage_profile_path

        expect(response.body).to include("プログラミング")
        expect(response.body).to include("study")
      end
    end
  end

  describe "PATCH /mypage/profile" do
    let!(:profile) { create(:profile, user:) }
    let(:fps) { create(:parent_tag, name: "FPS", slug: "fps", room_type: :game) }

    it "11個のタグで更新するとバリデーションエラーになる" do
      hobbies_text = (1..11).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      patch mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "10個以下のタグで更新すると成功する" do
      hobbies_text = (1..10).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      patch mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to have_http_status(:found)
    end

    it "bio が未入力だと更新できない" do
      hobbies_text = [ { name: "ゲーム", description: "" } ].to_json

      patch mypage_profile_path, params: { profile: { bio: "", hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("自己紹介を入力してください")
    end

    it "タグが0個だと更新できない" do
      patch mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: [].to_json } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("趣味タグを1つ以上追加してください")
    end

    it "parent_tag_id 付きで新規タグを保存すると HobbyParentTag が作成される" do
      hobbies_text = [ { name: "brandnewtag", description: "", parent_tag_id: fps.id } ].to_json

      patch mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      hobby = Hobby.find_by(normalized_name: "brandnewtag")
      expect(hobby.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(fps)
    end
  end

  describe "POST /mypage/profile" do
    it "作成成功後にマイページへリダイレクトする" do
      hobbies_text = [ { name: "ゲーム", description: "" } ].to_json

      post mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to redirect_to(mypage_root_path)
    end

    it "11個のタグで作成するとバリデーションエラーになりタグデータが保持される" do
      hobbies_text = (1..11).map { |i| { name: "タグ#{i}", description: "" } }.to_json

      post mypage_profile_path, params: { profile: { hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("タグ1")
    end

    it "bio が未入力だと作成できない" do
      hobbies_text = [ { name: "ゲーム", description: "" } ].to_json

      post mypage_profile_path, params: { profile: { bio: "", hobbies_text: } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("自己紹介を入力してください")
    end

    it "タグが0個だと作成できない" do
      post mypage_profile_path, params: { profile: { bio: "自己紹介", hobbies_text: [].to_json } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("趣味タグを1つ以上追加してください")
    end
  end

  describe "GET /mypage/profile/new" do
    it "作成済みなら一覧へリダイレクトしnoticeが出る" do
      create(:profile, user:)

      get new_mypage_profile_path

      expect(response).to redirect_to(profiles_path)
      follow_redirect!

      expect(response.body).to include("プロフィールは作成済みです")
    end
  end

  describe "旧URL後方互換 /my/profile/*" do
    it "GET /my/profile/new は /mypage/profile/new へリダイレクトする" do
      get "/my/profile/new"

      expect(response).to redirect_to("/mypage/profile/new")
    end

    it "GET /my/profile/edit は /mypage/profile/edit へリダイレクトする" do
      create(:profile, user:)

      get "/my/profile/edit"

      expect(response).to redirect_to("/mypage/profile/edit")
    end

    it "POST /my/profile は引き続きプロフィールを作成できる" do
      hobbies_text = [ { name: "ゲーム", description: "" } ].to_json

      post "/my/profile", params: { profile: { bio: "自己紹介", hobbies_text: } }

      expect(response).to redirect_to(mypage_root_path)
      expect(user.reload.profile).to be_present
    end

    it "PATCH /my/profile は引き続きプロフィールを更新できる" do
      profile = create(:profile, user:)
      hobbies_text = [ { name: "更新タグ", description: "" } ].to_json

      patch "/my/profile", params: { profile: { bio: "更新後", hobbies_text: } }

      expect(response).to redirect_to(profile_path(profile))
      expect(profile.reload.bio).to eq("更新後")
    end
  end
end
