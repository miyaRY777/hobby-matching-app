require "rails_helper"

RSpec.describe "ApplicationController", type: :request do
  describe "POST /users/sign_in" do
    it "プロフィール未作成ならプロフィール作成画面へリダイレクトする" do
      user = create(:user)

      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }

      expect(response).to redirect_to(new_my_profile_path)
    end

    it "プロフィール作成済みなら保存済みの遷移先を優先する" do
      user = create(:user)
      create(:profile, user:)

      get edit_my_profile_path
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }

      expect(response).to redirect_to(edit_my_profile_path)
    end
  end

  describe "不完全なプロフィール警告" do
    it "bio が空のプロフィールでは警告バナーが表示される" do
      user = create(:user)
      profile = create(:profile, user:)
      profile.update_column(:bio, "")
      sign_in user

      get profiles_path

      expect(response.body).to include("プロフィールの自己紹介またはタグが未入力です。編集ページから補完してください。")
    end

    it "タグがないプロフィールでは警告バナーが表示される" do
      user = create(:user)
      profile = create(:profile, user:)
      profile.profile_hobbies.delete_all
      sign_in user

      get profiles_path

      expect(response.body).to include("プロフィールの自己紹介またはタグが未入力です。編集ページから補完してください。")
    end

    it "プロフィール編集画面では警告バナーを表示しない" do
      user = create(:user)
      profile = create(:profile, user:)
      profile.update_column(:bio, "")
      sign_in user

      get edit_my_profile_path

      expect(response.body).not_to include("プロフィールの自己紹介またはタグが未入力です。編集ページから補完してください。")
    end
  end
end
